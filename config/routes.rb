Rails.application.routes.draw do
  resources :tax, only: [:index, :update]
  resources :lineitems
  resources :orders
  resources :reservations
  devise_for :users, skip: [:registrations]
  resources :products do
    post :get_barcode, on: :collection
    post :get_barcode_from_sku, on: :collection
    get :create_order, on: :collection
    get :start_scanning, on: :collection
    get :export, on: :collection
    post :import, on: :collection
    put :update_sync_with_modeprofi
  end
  root :to => 'products#index'
  mount ShopifyApp::Engine, at: '/'
  post 'webhook/get_hook'
  post 'webhook/update_shopify_product' => 'products#update_shopify_product'
  post 'webhook/create_product' => 'products#create_product'
  post 'webhook/delete_product' => 'products#delete_product'
  post 'webhook/create_order' => 'orders#webhook_create_order'
  post 'webhook/cancel_order' => 'orders#webhook_cancel_order'
  post 'webhook/notify_new_customer_shopify_admin' => 'products#notify_new_customer_shopify_admin'
  post 'webhook/notify_update_customer_shopify_admin' => 'products#notify_update_customer_shopify_admin'
  post 'webhook/validate_vat_id' => 'webhook#validate_vat_id'
  post '/change_sync' => 'products#change_sync'
  post '/change_sku_type' => 'products#change_sku_type'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/get_hook' => 'webhook#get_hook'
  get '/cancel_order' => 'orders#cancel_order'
  get '/print_order' => 'orders#print_order'
  get "/file/:id" => "orders#get_file"
  get '/suggestions' => 'products#suggestions', as: 'suggestions'
  get '/modelnumbers' => 'products#modelnumbers', as: 'modelnumbers'

  get '/approve_reservation' => 'reservations#approve_reservation', as: 'approvereservation'
  post '/update_reservation' => 'reservations#update_reservation', as: 'update_reservation'

end
