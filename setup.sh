#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE_FILE="${ROOT_DIR}/.env.example"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
VERSION_FILE="${ROOT_DIR}/VERSION"
VERSION="dev"

if [[ -f "${VERSION_FILE}" ]]; then
  VERSION="$(tr -d '\r\n' < "${VERSION_FILE}")"
fi

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

ensure_compose_ready() {
  if ! command_exists docker; then
    log_error "未检测到 docker 命令，请先安装 Docker。"
    exit 1
  fi

  if ! docker compose version >/dev/null 2>&1; then
    log_error "未检测到 docker compose，请先安装 Docker Compose 插件。"
    exit 1
  fi
}

generate_secret() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 64
}

read_env_value() {
  local key default line value
  key="${1:?}"
  default="${2:-}"

  if [[ -f "${ENV_FILE}" ]]; then
    line="$(grep -E "^${key}=" "${ENV_FILE}" | tail -n 1 || true)"
    if [[ -n "${line}" ]]; then
      value="${line#*=}"
      printf '%s' "${value}"
      return 0
    fi
  fi

  if [[ -f "${ENV_EXAMPLE_FILE}" ]]; then
    line="$(grep -E "^${key}=" "${ENV_EXAMPLE_FILE}" | tail -n 1 || true)"
    if [[ -n "${line}" ]]; then
      value="${line#*=}"
      printf '%s' "${value}"
      return 0
    fi
  fi

  printf '%s' "${default}"
}

prompt_text() {
  local prompt default input
  prompt="${1:?}"
  default="${2:-}"

  if [[ -n "${default}" ]]; then
    read -r -p "${prompt} [${default}]: " input
    printf '%s' "${input:-${default}}"
  else
    read -r -p "${prompt}: " input
    printf '%s' "${input}"
  fi
}

prompt_secret() {
  local prompt current allow_empty generated input
  prompt="${1:?}"
  current="${2:-}"
  allow_empty="${3:-false}"
  generated="${4:-}"

  if [[ -n "${current}" ]]; then
    read -r -s -p "${prompt} [留空保持当前值]: " input
    echo
    if [[ -z "${input}" ]]; then
      printf '%s' "${current}"
      return 0
    fi
    printf '%s' "${input}"
    return 0
  fi

  read -r -s -p "${prompt} [留空自动生成]: " input
  echo

  if [[ -z "${input}" ]]; then
    if [[ "${allow_empty}" == "true" ]]; then
      printf '%s' ""
    else
      printf '%s' "${generated}"
    fi
    return 0
  fi

  printf '%s' "${input}"
}

prompt_yes_no() {
  local prompt default input normalized
  prompt="${1:?}"
  default="${2:-y}"

  if [[ "${default}" == "y" ]]; then
    read -r -p "${prompt} [Y/n]: " input
    normalized="${input:-Y}"
  else
    read -r -p "${prompt} [y/N]: " input
    normalized="${input:-N}"
  fi

  case "${normalized}" in
    y|Y|yes|YES|Yes) return 0 ;;
    n|N|no|NO|No) return 1 ;;
    *)
      log_warn "输入无效，已按默认值处理。"
      [[ "${default}" == "y" ]]
      return
      ;;
  esac
}

select_captcha_provider() {
  local current choice
  current="${1:-none}"

  echo "请选择验证码提供方："
  echo "1. none（不启用）"
  echo "2. turnstile"
  echo "3. hcaptcha"
  read -r -p "输入选项 [当前: ${current}]: " choice

  case "${choice:-}" in
    "" )
      printf '%s' "${current}"
      ;;
    1 )
      printf '%s' "none"
      ;;
    2 )
      printf '%s' "turnstile"
      ;;
    3 )
      printf '%s' "hcaptcha"
      ;;
    * )
      log_warn "输入无效，已使用当前值。"
      printf '%s' "${current}"
      ;;
  esac
}

backup_existing_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    cp "${ENV_FILE}" "${ENV_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

write_env_file() {
  backup_existing_env

  cat > "${ENV_FILE}" <<EOF
AUTH_ENABLED=${AUTH_ENABLED}
AUTH_USERS=${AUTH_USERS}
AUTH_TOKEN_EXPIRY=${AUTH_TOKEN_EXPIRY}
AUTH_JWT_SECRET=${AUTH_JWT_SECRET}

NEXT_PUBLIC_API_BASE=${NEXT_PUBLIC_API_BASE}
NEXT_PUBLIC_CAPTCHA_PROVIDER=${NEXT_PUBLIC_CAPTCHA_PROVIDER}
NEXT_PUBLIC_TURNSTILE_SITE_KEY=${NEXT_PUBLIC_TURNSTILE_SITE_KEY}
TURNSTILE_SECRET_KEY=${TURNSTILE_SECRET_KEY}
NEXT_PUBLIC_HCAPTCHA_SITE_KEY=${NEXT_PUBLIC_HCAPTCHA_SITE_KEY}
HCAPTCHA_SECRET_KEY=${HCAPTCHA_SECRET_KEY}

NEXT_PUBLIC_AI_SUGGEST_ENABLED=${NEXT_PUBLIC_AI_SUGGEST_ENABLED}
NEXT_PUBLIC_AI_SUGGEST_THRESHOLD=${NEXT_PUBLIC_AI_SUGGEST_THRESHOLD}
NEXT_PUBLIC_AI_SUGGEST_REQUIRE_CAPTCHA=${NEXT_PUBLIC_AI_SUGGEST_REQUIRE_CAPTCHA}
AI_SUGGEST_BASE_URL=${AI_SUGGEST_BASE_URL}
AI_SUGGEST_MODEL=${AI_SUGGEST_MODEL}
AI_SUGGEST_API_KEY=${AI_SUGGEST_API_KEY}
AI_SUGGEST_PROMPT=${AI_SUGGEST_PROMPT}

AI_RANKINGS_ENABLED=${AI_RANKINGS_ENABLED}
NEXT_PUBLIC_AI_RANKINGS_ENABLED=${NEXT_PUBLIC_AI_RANKINGS_ENABLED}
AI_RANKINGS_BASE_URL=${AI_RANKINGS_BASE_URL}
AI_RANKINGS_MODEL=${AI_RANKINGS_MODEL}
AI_RANKINGS_API_KEY=${AI_RANKINGS_API_KEY}
AI_RANKINGS_RUN_AT=${AI_RANKINGS_RUN_AT}
AI_RANKINGS_TIMEZONE=${AI_RANKINGS_TIMEZONE}
AI_RANKINGS_RUN_ON_STARTUP=${AI_RANKINGS_RUN_ON_STARTUP}
AI_RANKINGS_MIN_ITEMS=${AI_RANKINGS_MIN_ITEMS}
AI_RANKINGS_DATA_DIR=${AI_RANKINGS_DATA_DIR}
ADMIN_DATA_DIR=${ADMIN_DATA_DIR}
AI_RANKINGS_SYNC_TOKEN=${AI_RANKINGS_SYNC_TOKEN}
EOF
}

show_summary() {
  echo "=============================="
  echo "FileSearch 配置摘要"
  echo "=============================="
  echo "认证启用: ${AUTH_ENABLED}"
  if [[ "${AUTH_ENABLED}" == "true" ]]; then
    echo "认证用户: ${AUTH_USERS%%,*}"
  fi
  echo "验证码: ${NEXT_PUBLIC_CAPTCHA_PROVIDER}"
  echo "AI 推荐: ${NEXT_PUBLIC_AI_SUGGEST_ENABLED}"
  echo "AI 排行榜: ${AI_RANKINGS_ENABLED}"
  echo "配置文件: ${ENV_FILE}"
}

run_wizard() {
  local existing_auth_users admin_user generated_password generated_secret current_captcha current_ai current_rankings
  local captcha_provider reuse_ai_rankings

  echo "=============================="
  echo "FileSearch 交互式部署向导 v${VERSION}"
  echo "=============================="
  echo "提示：脚本会生成根目录 .env，并由 docker-compose.yml 自动读取。"
  echo

  NEXT_PUBLIC_API_BASE="$(read_env_value NEXT_PUBLIC_API_BASE "http://127.0.0.1:8888")"
  AUTH_TOKEN_EXPIRY="$(read_env_value AUTH_TOKEN_EXPIRY "24")"
  NEXT_PUBLIC_AI_SUGGEST_THRESHOLD="$(read_env_value NEXT_PUBLIC_AI_SUGGEST_THRESHOLD "50")"
  AI_RANKINGS_RUN_AT="$(read_env_value AI_RANKINGS_RUN_AT "03:00")"
  AI_RANKINGS_TIMEZONE="$(read_env_value AI_RANKINGS_TIMEZONE "Asia/Shanghai")"
  AI_RANKINGS_RUN_ON_STARTUP="$(read_env_value AI_RANKINGS_RUN_ON_STARTUP "false")"
  AI_RANKINGS_MIN_ITEMS="$(read_env_value AI_RANKINGS_MIN_ITEMS "20")"
  AI_RANKINGS_DATA_DIR="$(read_env_value AI_RANKINGS_DATA_DIR "/app/data/rankings")"
  ADMIN_DATA_DIR="$(read_env_value ADMIN_DATA_DIR "/app/data/admin")"
  AI_SUGGEST_PROMPT="$(read_env_value AI_SUGGEST_PROMPT "")"

  if prompt_yes_no "是否启用后台认证（推荐）？" "$( [[ "$(read_env_value AUTH_ENABLED "true")" == "true" ]] && echo y || echo n )"; then
    AUTH_ENABLED="true"
    existing_auth_users="$(read_env_value AUTH_USERS "")"
    admin_user="${existing_auth_users%%:*}"
    if [[ -z "${admin_user}" || "${admin_user}" == "${existing_auth_users}" ]]; then
      admin_user="admin"
    fi
    admin_user="$(prompt_text "管理员用户名" "${admin_user}")"

    generated_password="$(generate_secret | head -c 20)"
    admin_password="$(prompt_secret "管理员密码（建议不要包含空格或 #）" "" "false" "${generated_password}")"
    if [[ "${admin_password}" == "${generated_password}" ]]; then
      log_info "已自动生成管理员密码：${admin_password}"
    fi

    AUTH_USERS="${admin_user}:${admin_password}"
    AUTH_TOKEN_EXPIRY="$(prompt_text "Token 过期时间（小时）" "${AUTH_TOKEN_EXPIRY}")"

    generated_secret="$(generate_secret)"
    AUTH_JWT_SECRET="$(prompt_secret "AUTH_JWT_SECRET（留空自动生成）" "$(read_env_value AUTH_JWT_SECRET "")" "false" "${generated_secret}")"
    if [[ "${AUTH_JWT_SECRET}" == "${generated_secret}" ]]; then
      log_info "已自动生成 AUTH_JWT_SECRET。"
    fi
  else
    AUTH_ENABLED="false"
    AUTH_USERS=""
    AUTH_TOKEN_EXPIRY="24"
    AUTH_JWT_SECRET=""
  fi

  current_captcha="$(read_env_value NEXT_PUBLIC_CAPTCHA_PROVIDER "none")"
  captcha_provider="$(select_captcha_provider "${current_captcha}")"
  NEXT_PUBLIC_CAPTCHA_PROVIDER="${captcha_provider}"
  NEXT_PUBLIC_TURNSTILE_SITE_KEY=""
  TURNSTILE_SECRET_KEY=""
  NEXT_PUBLIC_HCAPTCHA_SITE_KEY=""
  HCAPTCHA_SECRET_KEY=""

  case "${NEXT_PUBLIC_CAPTCHA_PROVIDER}" in
    turnstile)
      NEXT_PUBLIC_TURNSTILE_SITE_KEY="$(prompt_text "Turnstile Site Key" "$(read_env_value NEXT_PUBLIC_TURNSTILE_SITE_KEY "")")"
      TURNSTILE_SECRET_KEY="$(prompt_text "Turnstile Secret Key" "$(read_env_value TURNSTILE_SECRET_KEY "")")"
      ;;
    hcaptcha)
      NEXT_PUBLIC_HCAPTCHA_SITE_KEY="$(prompt_text "hCaptcha Site Key" "$(read_env_value NEXT_PUBLIC_HCAPTCHA_SITE_KEY "")")"
      HCAPTCHA_SECRET_KEY="$(prompt_text "hCaptcha Secret Key" "$(read_env_value HCAPTCHA_SECRET_KEY "")")"
      ;;
  esac

  current_ai="$(read_env_value NEXT_PUBLIC_AI_SUGGEST_ENABLED "false")"
  if prompt_yes_no "是否启用 AI 推荐？" "$( [[ "${current_ai}" == "true" ]] && echo y || echo n )"; then
    NEXT_PUBLIC_AI_SUGGEST_ENABLED="true"
    AI_SUGGEST_BASE_URL="$(prompt_text "AI 接口地址（OpenAI 兼容）" "$(read_env_value AI_SUGGEST_BASE_URL "")")"
    AI_SUGGEST_MODEL="$(prompt_text "AI 模型名称" "$(read_env_value AI_SUGGEST_MODEL "")")"
    AI_SUGGEST_API_KEY="$(prompt_text "AI API Key" "$(read_env_value AI_SUGGEST_API_KEY "")")"
    NEXT_PUBLIC_AI_SUGGEST_THRESHOLD="$(prompt_text "AI 触发阈值" "${NEXT_PUBLIC_AI_SUGGEST_THRESHOLD}")"

    if [[ "${NEXT_PUBLIC_CAPTCHA_PROVIDER}" != "none" ]] && prompt_yes_no "AI 推荐是否要求先通过验证码？" "$( [[ "$(read_env_value NEXT_PUBLIC_AI_SUGGEST_REQUIRE_CAPTCHA "false")" == "true" ]] && echo y || echo n )"; then
      NEXT_PUBLIC_AI_SUGGEST_REQUIRE_CAPTCHA="true"
    else
      NEXT_PUBLIC_AI_SUGGEST_REQUIRE_CAPTCHA="false"
      if [[ "${NEXT_PUBLIC_CAPTCHA_PROVIDER}" == "none" ]]; then
        log_warn "当前未启用验证码，AI 推荐将不会要求先验证。"
      fi
    fi
  else
    NEXT_PUBLIC_AI_SUGGEST_ENABLED="false"
    NEXT_PUBLIC_AI_SUGGEST_THRESHOLD="50"
    NEXT_PUBLIC_AI_SUGGEST_REQUIRE_CAPTCHA="false"
    AI_SUGGEST_BASE_URL=""
    AI_SUGGEST_MODEL=""
    AI_SUGGEST_API_KEY=""
  fi

  current_rankings="$(read_env_value AI_RANKINGS_ENABLED "false")"
  if prompt_yes_no "是否启用 AI 排行榜？" "$( [[ "${current_rankings}" == "true" ]] && echo y || echo n )"; then
    AI_RANKINGS_ENABLED="true"
    NEXT_PUBLIC_AI_RANKINGS_ENABLED="true"

    if [[ "${NEXT_PUBLIC_AI_SUGGEST_ENABLED}" == "true" ]] && prompt_yes_no "排行榜是否复用 AI 推荐的接口配置？" "y"; then
      reuse_ai_rankings="true"
      AI_RANKINGS_BASE_URL=""
      AI_RANKINGS_MODEL=""
      AI_RANKINGS_API_KEY=""
    else
      reuse_ai_rankings="false"
      AI_RANKINGS_BASE_URL="$(prompt_text "排行榜 AI 接口地址（留空表示不复用时手动填写）" "$(read_env_value AI_RANKINGS_BASE_URL "")")"
      AI_RANKINGS_MODEL="$(prompt_text "排行榜 AI 模型名称" "$(read_env_value AI_RANKINGS_MODEL "")")"
      AI_RANKINGS_API_KEY="$(prompt_text "排行榜 AI API Key" "$(read_env_value AI_RANKINGS_API_KEY "")")"
    fi

    AI_RANKINGS_RUN_AT="$(prompt_text "排行榜每日执行时间（HH:mm）" "${AI_RANKINGS_RUN_AT}")"
    AI_RANKINGS_TIMEZONE="$(prompt_text "排行榜时区" "${AI_RANKINGS_TIMEZONE}")"

    if prompt_yes_no "容器启动后立即执行一次排行榜生成？" "$( [[ "${AI_RANKINGS_RUN_ON_STARTUP}" == "true" ]] && echo y || echo n )"; then
      AI_RANKINGS_RUN_ON_STARTUP="true"
    else
      AI_RANKINGS_RUN_ON_STARTUP="false"
    fi

    AI_RANKINGS_MIN_ITEMS="$(prompt_text "排行榜最少条目数" "${AI_RANKINGS_MIN_ITEMS}")"
    AI_RANKINGS_SYNC_TOKEN="$(prompt_secret "AI_RANKINGS_SYNC_TOKEN（留空自动生成）" "$(read_env_value AI_RANKINGS_SYNC_TOKEN "")" "false" "$(generate_secret | head -c 32)")"
    if [[ -z "${AI_RANKINGS_SYNC_TOKEN}" ]]; then
      AI_RANKINGS_SYNC_TOKEN="$(generate_secret | head -c 32)"
      log_info "已自动生成 AI_RANKINGS_SYNC_TOKEN。"
    fi
  else
    AI_RANKINGS_ENABLED="false"
    NEXT_PUBLIC_AI_RANKINGS_ENABLED="false"
    AI_RANKINGS_BASE_URL=""
    AI_RANKINGS_MODEL=""
    AI_RANKINGS_API_KEY=""
    AI_RANKINGS_RUN_AT="03:00"
    AI_RANKINGS_TIMEZONE="Asia/Shanghai"
    AI_RANKINGS_RUN_ON_STARTUP="false"
    AI_RANKINGS_MIN_ITEMS="20"
    AI_RANKINGS_SYNC_TOKEN=""
  fi

  write_env_file
  log_info "已生成配置文件：${ENV_FILE}"
  show_summary

  if prompt_yes_no "是否现在直接启动容器？" "y"; then
    ensure_compose_ready
    (cd "${ROOT_DIR}" && docker compose up -d --build)
    log_info "容器启动命令已执行。"
  fi
}

show_status() {
  ensure_compose_ready
  (cd "${ROOT_DIR}" && docker compose ps)
}

show_logs() {
  ensure_compose_ready
  (cd "${ROOT_DIR}" && docker compose logs -f --tail=100)
}

up_stack() {
  ensure_compose_ready
  (cd "${ROOT_DIR}" && docker compose up -d --build)
}

down_stack() {
  ensure_compose_ready
  (cd "${ROOT_DIR}" && docker compose down)
}

show_help() {
  cat <<EOF
FileSearch 部署助手 v${VERSION}

用法:
  ./setup.sh               打开交互菜单
  ./setup.sh wizard        运行交互式配置向导
  ./setup.sh up            构建并启动容器
  ./setup.sh down          停止并移除容器
  ./setup.sh status        查看容器状态
  ./setup.sh logs          查看最近日志
  ./setup.sh version       查看版本
  ./setup.sh help          查看帮助
EOF
}

show_menu() {
  local choice
  while true; do
    echo
    echo "=============================="
    echo " FileSearch 部署助手 v${VERSION}"
    echo "=============================="
    echo "1. 初始化/更新部署配置"
    echo "2. 构建并启动容器"
    echo "3. 查看容器状态"
    echo "4. 查看容器日志"
    echo "5. 停止容器"
    echo "6. 查看帮助"
    echo "0. 退出"
    read -r -p "请选择操作: " choice

    case "${choice}" in
      1) run_wizard ;;
      2) up_stack ;;
      3) show_status ;;
      4) show_logs ;;
      5) down_stack ;;
      6) show_help ;;
      0) exit 0 ;;
      *) log_warn "无效选项，请重新输入。" ;;
    esac
  done
}

case "${1:-menu}" in
  wizard|init)
    run_wizard
    ;;
  up)
    up_stack
    ;;
  down)
    down_stack
    ;;
  status)
    show_status
    ;;
  logs)
    show_logs
    ;;
  version)
    echo "${VERSION}"
    ;;
  help|-h|--help)
    show_help
    ;;
  menu)
    show_menu
    ;;
  *)
    log_error "未知命令: ${1}"
    show_help
    exit 1
    ;;
esac
