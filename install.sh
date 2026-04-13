#!/usr/bin/env bash

set -euo pipefail

VERSION="0.1.0"
REPO_URL="${FILESEARCH_REPO_URL:-https://github.com/cosmaut/FileSearch.git}"
REPO_BRANCH="${FILESEARCH_REPO_BRANCH:-main}"
DEFAULT_INSTALL_DIR="/opt/FileSearch"
GLOBAL_CMD_PATH="/usr/local/bin/filesearch"
LAST_STASH_REF=""

if [[ -d "/www/wwwroot" ]]; then
  DEFAULT_INSTALL_DIR="/www/wwwroot/FileSearch"
fi

INSTALL_DIR="${FILESEARCH_INSTALL_DIR:-${DEFAULT_INSTALL_DIR}}"

green="\033[0;32m"
yellow="\033[0;33m"
red="\033[0;31m"
plain="\033[0m"

log_info() {
  echo -e "${green}$1${plain}"
}

log_warn() {
  echo -e "${yellow}$1${plain}"
}

log_error() {
  echo -e "${red}$1${plain}"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

backup_local_changes_if_needed() {
  local status_output stash_message stash_before stash_after

  status_output="$(git -C "${INSTALL_DIR}" status --porcelain)"
  if [[ -z "${status_output}" ]]; then
    return 0
  fi

  log_warn "检测到安装目录存在本地修改，正在自动备份后再更新代码..."
  stash_message="filesearch-installer-auto-backup-$(date +%Y%m%d%H%M%S)"
  stash_before="$(git -C "${INSTALL_DIR}" stash list | head -n 1 || true)"
  git -C "${INSTALL_DIR}" stash push --include-untracked -m "${stash_message}" >/dev/null
  stash_after="$(git -C "${INSTALL_DIR}" stash list | head -n 1 || true)"

  if [[ -n "${stash_after}" && "${stash_after}" != "${stash_before}" ]]; then
    LAST_STASH_REF="${stash_after%%:*}"
    log_info "已将本地修改备份到 Git stash：${LAST_STASH_REF}"
  else
    log_warn "未能确认 stash 条目，请稍后手动执行 git stash list 检查备份是否成功。"
  fi
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    log_error "请使用 root 或 sudo 运行安装脚本。"
    echo "示例：curl -fsSL https://raw.githubusercontent.com/cosmaut/FileSearch/main/install.sh | sudo bash"
    exit 1
  fi
}

detect_package_manager() {
  if command_exists apt-get; then
    printf '%s' "apt"
    return 0
  fi

  if command_exists dnf; then
    printf '%s' "dnf"
    return 0
  fi

  if command_exists yum; then
    printf '%s' "yum"
    return 0
  fi

  log_error "暂不支持当前系统的包管理器，请手动安装 git、curl、ca-certificates、docker 与 docker compose。"
  exit 1
}

install_packages() {
  local manager
  manager="$(detect_package_manager)"

  case "${manager}" in
    apt)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y git curl ca-certificates
      ;;
    dnf)
      dnf install -y git curl ca-certificates
      ;;
    yum)
      yum install -y git curl ca-certificates
      ;;
  esac
}

install_compose_plugin() {
  local manager
  manager="$(detect_package_manager)"

  case "${manager}" in
    apt)
      apt-get install -y docker-compose-plugin || true
      ;;
    dnf)
      dnf install -y docker-compose-plugin || true
      ;;
    yum)
      yum install -y docker-compose-plugin || true
      ;;
  esac
}

ensure_base_dependencies() {
  if command_exists git && command_exists curl; then
    return 0
  fi

  log_info "正在安装基础依赖（git / curl / ca-certificates）..."
  install_packages
}

enable_docker_service() {
  if command_exists systemctl; then
    systemctl enable --now docker >/dev/null 2>&1 || true
    return 0
  fi

  if command_exists service; then
    service docker start >/dev/null 2>&1 || true
  fi
}

ensure_docker() {
  if command_exists docker && docker compose version >/dev/null 2>&1; then
    enable_docker_service
    return 0
  fi

  log_warn "未检测到 Docker 或 docker compose，正在自动安装 Docker..."
  curl -fsSL https://get.docker.com | sh
  enable_docker_service

  if ! command_exists docker; then
    log_error "Docker 安装失败，请手动检查。"
    exit 1
  fi

  if ! docker compose version >/dev/null 2>&1; then
    log_warn "正在尝试安装 docker compose 插件..."
    install_compose_plugin
  fi

  if ! docker compose version >/dev/null 2>&1; then
    log_error "docker compose 仍不可用，请手动安装 Docker Compose 插件后重试。"
    exit 1
  fi
}

prepare_install_dir() {
  local parent_dir
  parent_dir="$(dirname "${INSTALL_DIR}")"
  mkdir -p "${parent_dir}"
}

sync_repository() {
  if [[ -d "${INSTALL_DIR}/.git" ]]; then
    log_info "检测到已有 FileSearch 安装目录，正在更新到最新版本..."
    git -C "${INSTALL_DIR}" fetch --all --tags --prune
    backup_local_changes_if_needed
    git -C "${INSTALL_DIR}" checkout "${REPO_BRANCH}"
    git -C "${INSTALL_DIR}" pull --ff-only origin "${REPO_BRANCH}"
    return 0
  fi

  if [[ -d "${INSTALL_DIR}" ]] && [[ -n "$(ls -A "${INSTALL_DIR}" 2>/dev/null || true)" ]]; then
    log_error "安装目录 ${INSTALL_DIR} 已存在且不是 Git 仓库。"
    echo "请手动清理目录，或使用 FILESEARCH_INSTALL_DIR 指定其他安装路径后重试。"
    exit 1
  fi

  log_info "正在下载 FileSearch 到 ${INSTALL_DIR} ..."
  git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${INSTALL_DIR}"
}

install_global_command() {
  cat > "${GLOBAL_CMD_PATH}" <<EOF
#!/usr/bin/env bash
cd "${INSTALL_DIR}"
exec "${INSTALL_DIR}/setup.sh" "\$@"
EOF
  chmod +x "${GLOBAL_CMD_PATH}"
}

print_install_summary() {
  echo "================================================================"
  echo " FileSearch 安装完成 "
  echo "================================================================"
  echo "安装目录: ${INSTALL_DIR}"
  echo "全局命令: ${GLOBAL_CMD_PATH}"
  echo "仓库地址: ${REPO_URL}"
  echo "分支: ${REPO_BRANCH}"
  if [[ -n "${LAST_STASH_REF}" ]]; then
    echo "本地备份: ${LAST_STASH_REF}（如需恢复，可在项目目录执行 git stash pop ${LAST_STASH_REF}）"
  fi
  echo
  echo "后续可直接使用："
  echo "  filesearch               打开部署助手"
  echo "  filesearch wizard        运行交互式配置向导"
  echo "  filesearch up            构建并启动容器"
  echo "  filesearch status        查看容器状态"
  echo "  filesearch logs          查看容器日志"
}

launch_wizard() {
  chmod +x "${INSTALL_DIR}/setup.sh" "${INSTALL_DIR}/install.sh" || true
  print_install_summary

  if [[ -e /dev/tty ]]; then
    log_info "正在进入 FileSearch 交互式部署向导..."
    cd "${INSTALL_DIR}"
    bash ./setup.sh wizard </dev/tty
    return 0
  fi

  log_warn "当前没有可用的交互终端，无法自动进入向导。"
  echo "请手动执行："
  echo "  cd ${INSTALL_DIR}"
  echo "  ./setup.sh"
}

main() {
  echo "================================================================"
  echo " 正在安装 FileSearch v${VERSION}"
  echo "================================================================"
  require_root
  ensure_base_dependencies
  ensure_docker
  prepare_install_dir
  sync_repository
  install_global_command
  launch_wizard
}

main "$@"
