defmodule Servy.Handler do
	def handle(request) do
		request
		|> parse
		|> rewrite_path
		|> log
		|> route
		|> emojify
		|> track
		|> format_response
	end

	def emojify(%{status: 200} = conv) do
		emojies = String.duplicate("🎉", 5)
		body = emojies <> "\n" <> conv.resp_body <> "\n" <> emojies

		%{ conv | resp_body: body }
	end

	def emojify(conv), do: conv

	def track(%{status: 404, path: path} = conv) do
		IO.puts "Warning: #{path} is on the loose!"
		conv
	end

	def track(conv), do: conv

	def rewrite_path(%{path: "/wildlife"} = conv) do
		%{ conv | path: "/wildthings" }
	end

	def rewrite_path(%{path: "/bears?id=" <> id} = conv) do
		%{ conv | path: "/bears/#{id}" }
	end

	def rewrite_path(conv), do: conv

	def log(conv), do: IO.inspect conv

	def parse(request) do
		# Parse the request string into a map:
		[method, path, _] =
			request 
			|> String.split("\n") 
			|> List.first
			|> String.split(" ")

		%{ method: method, 
		   path: path, 
		   resp_body: "",
		   status: nil 
		 }
	end

	# def route(conv) do
	# 	# One arrity function calling a three arrity function.
	# 	route(conv, conv.method, conv.path)
	# end

	# Function clauses (three arrity)
	def route(%{method: "GET", path: "/wildthings" } = conv) do
		%{ conv | status: 200, resp_body: "Bears, Lions, Tigers" }
	end

	def route(%{method: "GET", path: "/bears" } = conv) do
		%{ conv | status: 200, resp_body: "Teddy. Smokey, Paddington" }
	end

	def route(%{method: "GET", path: "/bears/" <> id } = conv) do
		%{ conv | status: 200, resp_body: "Bear #{id}" }
	end

	def route(%{method: "DELETE", path: "/bears/" <> _id } = conv) do
  		%{ conv | status: 403, resp_body: "Deleting a bear is forbidden!"}
	end

	def route(%{method: "GET", path: "/about"} = conv) do
		Path.expand("../../pages", __DIR__)
		|> Path.join("about.html")
		|> File.read
		|> handle_file(conv)
	end

	def route(%{path: path } = conv) do
		%{ conv | status: 404, resp_body: "No #{path} here!" }
	end

	def handle_file({:ok, content}, conv) do
		%{ conv | status: 200, resp_body: content }
	end

	def handle_file({:error, :enoent}, conv) do
		%{ conv | status: 404, resp_body: "File not found!" }
	end

	def handle_file({:error, reason}, conv) do
		%{ conv | status: 500, resp_body: "File error #{reason}" }
	end

	def format_response(conv) do
		# Use values in the map to create an HTTP response string.
		"""
		HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
		Content-Type: text/html
		Content-Length: #{String.length(conv.resp_body)}

		#{conv.resp_body}
		"""
	end

	defp status_reason(code) do
		%{
		  200 => "OK",
		  201 => "Created",
		  401 => "Unauthorized",
		  403 => "Forbidden",
		  404 => "Not Found",
		  500 => "Internal Server Error"
		} [code]
	end
end

request = """
GET /about HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)
IO.puts response


request = """
GET /bears?id=1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)
IO.puts response

request = """
GET /wildlife HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)
IO.puts response


request = """
GET /bigfoot HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)
IO.puts response


request = """
GET /bears HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)
IO.puts response

request = """
GET /bears/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)
IO.puts response

request = """
GET /wildthings HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)
IO.puts response

# def route(%{method: "GET", path: "/about"} = conv) do
	# 	file = 
	#       Path.expand("../../pages", __DIR__)
	#       |> Path.join("about.html")

	# 	case File.read(file) do 
	# 		{:ok, content} ->
	# 		  %{ conv | status: 200, resp_body: content }

	# 		{:error, :enoent} ->
	# 		  %{ conv | status: 404, resp_body: "File not found!" }
			
	# 		{:error, reason} ->
	# 		  %{ conv | status: 500, resp_body: "File error: #{reason}" }
	#  	end
	# end
