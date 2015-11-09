Swagger::Docs::Config.register_apis(
  "v1" => {
    api_file_path: "public",
    base_api_controller: "Api::BaseController",
    base_path: "https://#{ENV['SERVERNAME']}",
    :attributes => {
      :info => {
        "title" => "API",
        "description" => "This is the live documentation of the Volpino API. The current API is v1, please use <a href='https://#{ENV['SERVERNAME']}/api/'>http://#{ENV['SERVERNAME']}/api/</a> as base URL." }
    }
  }
)
