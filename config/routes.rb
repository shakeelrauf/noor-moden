Rails.application.routes.draw do
  resources :orders
  devise_for :users
  resources :products do
    post :get_barcode, on: :collection
    post :get_barcode_from_sku, on: :collection
    get :create_order, on: :collection
    get :start_scanning, on: :collection
  end
  root :to => 'products#index'
  mount ShopifyApp::Engine, at: '/'
  post 'webhook/get_hook'
  post 'webhook/update_shopify_product' => 'products#update_shopify_product'
  post 'webhook/create_product' => 'products#create_product'
  post 'webhook/delete_product' => 'products#delete_product'
  post 'webhook/notify_new_customer_shopify_admin' => 'products#notify_new_customer_shopify_admin'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/get_hook' => 'webhook#get_hook'

end
