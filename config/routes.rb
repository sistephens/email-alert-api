Rails.application.routes.draw do
  status_updates_hostname = ENV.fetch("STATUS_UPDATES_HOSTNAME_PREFIX", "email-status-updates")

  constraints host: /^#{Regexp.escape(status_updates_hostname)}/ do
    resources :status_updates, path: "/", only: %i[create]
  end

  constraints host: /^(?!#{Regexp.escape(status_updates_hostname)})/ do
    resources :subscriber_lists, path: "subscriber-lists", only: [:create]
    get "/subscriber-lists", to: "subscriber_lists#show"

    resources :notifications, only: %i[create index show]
    resources :status_updates, path: "status-updates", only: %i[create]

    get "/healthcheck", to: "healthcheck#check"

    post "/unsubscribe/:uuid", to: "unsubscribe#unsubscribe"
  end
end
