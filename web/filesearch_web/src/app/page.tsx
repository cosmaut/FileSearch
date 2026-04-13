import type { Metadata } from "next";
import { headers } from "next/headers";
import HomeClient from "@/components/home-client";
import { LanguageInitializer } from "@/components/language-initializer";
import { detectPreferredLanguage, languageToLocale, normalizeLanguage } from "@/lib/i18n";
import { readRankingDataset } from "@/lib/rankings";
import { rankingsEnabled, rankingsNavEnabled } from "@/lib/rankings-config";
import { siteBrand, siteUrl } from "@/lib/site-config";

export const dynamic = "force-dynamic";

type LangConfig = {
  title: string;
  description: string;
  keywords: string[];
  ogLocale: string;
};

const langMap: Record<string, LangConfig> = {
  "zh-CN": {
    title: `${siteBrand} | 文件搜索`,
    description: "免费搜索动漫与网盘资源，无需登录，快速聚合多平台结果。",
    keywords: ["免费搜索动漫", "搜索动漫", "免费动漫", "无需登录", "网盘搜索", "动漫搜索"],
    ogLocale: "zh_CN",
  },
  "zh-TW": {
    title: `${siteBrand} | 文件搜尋`,
    description: "免費搜尋動漫與網盤資源，無需登入，快速聚合多平台結果。",
    keywords: ["免費搜尋動漫", "搜尋動漫", "免費動漫", "無需登入", "網盤搜尋", "動漫搜尋"],
    ogLocale: "zh_TW",
  },
  en: {
    title: `${siteBrand} | Anime Search`,
    description: "Free anime and netdisk search with no login required, fast multi-source results.",
    keywords: ["anime search", "free anime", "no login", "netdisk search", "anime resources"],
    ogLocale: "en_US",
  },
  ja: {
    title: `${siteBrand} | アニメ検索`,
    description: "無料でアニメとクラウド資源を検索、ログイン不要、複数ソースを高速統合。",
    keywords: ["アニメ検索", "無料アニメ", "ログイン不要", "クラウド検索"],
    ogLocale: "ja_JP",
  },
  ru: {
    title: `${siteBrand} | Поиск аниме`,
    description: "Бесплатный поиск аниме и облачных ресурсов без входа, быстрые результаты.",
    keywords: ["поиск аниме", "бесплатное аниме", "без входа", "поиск облака"],
    ogLocale: "ru_RU",
  },
  fr: {
    title: `${siteBrand} | Recherche Anime`,
    description: "Recherche gratuite d'anime et de ressources cloud sans connexion, résultats rapides.",
    keywords: ["recherche anime", "anime gratuit", "sans connexion", "recherche cloud"],
    ogLocale: "fr_FR",
  },
};

const resolveLang = (value?: string) => languageToLocale(normalizeLanguage(value));

export async function generateMetadata({
  searchParams,
}: {
  searchParams?: Promise<{ lang?: string; q?: string; auto?: string }>;
}): Promise<Metadata> {
  const params = await searchParams;
  const requestHeaders = await headers();
  const lang = params?.lang
    ? resolveLang(params.lang)
    : languageToLocale(detectPreferredLanguage(requestHeaders.get("accept-language")));
  const config = langMap[lang];
  const langParam = `?lang=${encodeURIComponent(lang)}`;
  const q = params?.q?.trim();

  if (q) {
    return {
      title: `${q} | ${siteBrand}`,
      description: `${q} - 进入 ${siteBrand} 首页并快速搜索相关动漫资源。`,
      robots: {
        index: true,
        follow: true,
      },
      alternates: {
        canonical: `/?q=${encodeURIComponent(q)}`,
      },
      openGraph: {
        title: `${q} | ${siteBrand}`,
        description: `${q} - 进入 ${siteBrand} 首页并快速搜索相关动漫资源。`,
        url: `${siteUrl}/?q=${encodeURIComponent(q)}`,
        siteName: siteBrand,
        locale: config.ogLocale,
        type: "website",
      },
      twitter: {
        card: "summary",
        title: `${q} | ${siteBrand}`,
        description: `${q} - 进入 ${siteBrand} 首页并快速搜索相关动漫资源。`,
      },
    };
  }

  return {
    title: config.title,
    description: config.description,
    keywords: config.keywords,
    alternates: {
      canonical: `/${langParam}`,
      languages: {
        "zh-CN": `/?lang=zh-CN`,
        "zh-TW": `/?lang=zh-TW`,
        en: `/?lang=en`,
        ja: `/?lang=ja`,
        ru: `/?lang=ru`,
        fr: `/?lang=fr`,
      },
    },
    openGraph: {
      title: config.title,
      description: config.description,
      url: `${siteUrl}/${langParam}`,
      siteName: siteBrand,
      locale: config.ogLocale,
      alternateLocale: ["zh_CN", "zh_TW", "en_US", "ja_JP", "ru_RU", "fr_FR"].filter(
        (locale) => locale !== config.ogLocale,
      ),
      type: "website",
    },
    twitter: {
      card: "summary",
      title: config.title,
      description: config.description,
    },
  };
}

export default async function Page({
  searchParams,
}: {
  searchParams?: Promise<{ lang?: string; q?: string; auto?: string }>;
}) {
  const params = await searchParams;
  const requestHeaders = await headers();
  const initialLanguage = params?.lang
    ? normalizeLanguage(params.lang)
    : detectPreferredLanguage(requestHeaders.get("accept-language"));
  const rankingDataset = rankingsEnabled() ? await readRankingDataset() : null;
  const showRankings = rankingsNavEnabled();

  return (
    <>
      <LanguageInitializer initialLanguage={initialLanguage} />
      <HomeClient initialLanguage={initialLanguage} showRankings={showRankings} />
      {rankingDataset && params?.q ? (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "SearchResultsPage",
              name: `${params.q} | ${siteBrand}`,
              url: `${siteUrl}/?q=${encodeURIComponent(params.q)}`,
              mainEntity: {
                "@type": "Thing",
                name: params.q,
              },
            }),
          }}
        />
      ) : null}
    </>
  );
}
