const normalizeUrl = (value?: string) => {
  const raw = (value || "").trim();

  if (!raw) {
    return "http://localhost:3200";
  }

  return raw.replace(/\/+$/, "");
};

export const siteUrl = normalizeUrl(process.env.NEXT_PUBLIC_SITE_URL);

export const siteBrand = "FileSearch";
export const siteOrganization = "Cosmaut";
export const siteRepositoryUrl = "https://github.com/cosmaut/FileSearch";
export const adminEmailPlaceholder = "admin@filesearch.local";
