$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()
Write-Host "Server started on http://127.0.0.1:$port/"

try {
    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $response = $context.Response
            $path = $context.Request.Url.LocalPath
            
            if ($path -eq "/") { $path = "/index.html" }
            $file = Join-Path $PWD $path
            
            if (Test-Path $file -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($file)
                $response.ContentLength64 = $bytes.Length
                
                # Determine ContentType
                if ($file.EndsWith(".html")) { $response.ContentType = "text/html; charset=utf-8" }
                elseif ($file.EndsWith(".css")) { $response.ContentType = "text/css" }
                elseif ($file.EndsWith(".js")) { $response.ContentType = "application/javascript" }
                elseif ($file.EndsWith(".png")) { $response.ContentType = "image/png" }
                elseif ($file.EndsWith(".webp")) { $response.ContentType = "image/webp" }
                elseif ($file.EndsWith(".jpg") -or $file.EndsWith(".jpeg")) { $response.ContentType = "image/jpeg" }
                
                try {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                } catch {
                    # Ignore write exceptions (e.g., client closed connection prematurely)
                }
            } else {
                $response.StatusCode = 404
            }
        } catch {
            Write-Warning "Failed to process request: $_"
        } finally {
            if ($null -ne $response) {
                try { $response.Close() } catch {}
            }
        }
    }
} finally {
    $listener.Stop()
}
