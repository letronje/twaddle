Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :twitter, "AG0C4uMJuDqorn1g0w9DA", "eVM08xyDjPmWsLjfo3uRH5Bx4punjMhfa2jDNb0rNk"
end
