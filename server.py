import http.server
import socket
import socketserver
import sys

PORT = 8080

# Configurar o tipo MIME do APK de forma explícita
# Isso garante que o navegador do Android 2.3 saiba que é um instalador e inicie a instalação.
Handler = http.server.SimpleHTTPRequestHandler
Handler.extensions_map.update({
    '.apk': 'application/vnd.android.package-archive',
})

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Não precisa realizar conexão real, serve apenas para identificar a interface de rede ativa
        s.connect(('8.8.8.8', 80))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

ip_local = get_ip()

print("=" * 60)
print("   Servidor de Downloads para LG Optimus 3D Iniciado!   ")
print("=" * 60)
print(f" No computador (para testes):  http://localhost:{PORT}")
print(f" No seu LG Optimus 3D (na mesma rede Wi-Fi), acesse:")
print(f" \033[1;32mhttp://{ip_local}:{PORT}\033[0m")
print("=" * 60)
print(" Pressione Ctrl+C no terminal para parar o servidor.")
print("=" * 60)

# Tratar reuso de endereço para evitar erro "Address already in use" se reiniciar rapidamente
socketserver.TCPServer.allow_reuse_address = True

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor finalizado pelo usuário.")
        sys.exit(0)
