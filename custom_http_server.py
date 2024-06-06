from http.server import BaseHTTPRequestHandler, HTTPServer

class CustomHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(bytes("Hi.This is a custom message reply!", "utf-8"))

def run():
    print('Starting server...')
    server_address = ('', 80)
    httpd = HTTPServer(server_address, CustomHTTPRequestHandler)
    print('Server running...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()