const http = require('http');
const https = require('https');

const TARGET_PORT = 5050;
const PROXY_PORT = 11434;
const TAVILY_API_KEY = process.env.TAVILY_API_KEY;
const ENABLE_TAVILY = process.argv[2] === "1";

console.log(`[Elite Blackwell Shim]`);
console.log(`- Puerto: ${PROXY_PORT} -> ${TARGET_PORT}`);
console.log(`- Tavily Status: ${ENABLE_TAVILY ? "ACTIVADO (Agentic)" : "DESACTIVADO (Directo)"}`);

const path = require('path');
const LOG_FILE = path.join(__dirname, 'shim_debug.log');
function logToFile(msg) { fs.appendFileSync(LOG_FILE, `[${new Date().toISOString()}] ${msg}\n`); }

async function searchTavily(query) {
    if (!TAVILY_API_KEY || !query) {
        logToFile("Búsqueda cancelada: No hay API Key o query.");
        return "";
    }
    logToFile(`Iniciando búsqueda para: ${query}`);

    return new Promise((resolve) => {
        const data = JSON.stringify({
            api_key: TAVILY_API_KEY,
            query: query,
            search_depth: "advanced",
            max_results: 5
        });


        const req = https.request({
            hostname: 'api.tavily.com',
            path: '/search',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        }, (res) => {
            let body = '';
            res.on('data', (d) => body += d);
            res.on('end', () => {
                try {
                    const json = JSON.parse(body);
                    const results = (json.results || []).map(r => `[${r.title}]: ${r.content} (Fuente: ${r.url})`).join('\n\n');
                    logToFile(`Búsqueda terminada. Resultados: ${json.results?.length || 0}`);
                    resolve(results ? `\n--- INFORMACIÓN DE INTERNET (RECIÉN BUSCADA) ---\n${results}\n--- FIN DE INFORMACIÓN ---\n` : "");
                } catch (e) {
                    logToFile(`Error parseando Tavily: ${e.message}. Body: ${body.substring(0, 100)}`);
                    resolve("");
                }

            });
        });

        req.on('error', (e) => {
            logToFile(`Error de red Tavily: ${e.message}`);
            resolve("");
        });
        req.write(data);
        req.end();

        // Timeout de seguridad para no bloquear al usuario
        setTimeout(() => {
            logToFile("Timeout de Tavily (7s)");
            resolve("");
        }, 7000);

    });
}

const server = http.createServer((req, res) => {
    let url = req.url;
    let targetPath = url;
    console.log(`[Proxy] ${req.method} ${url}`);

    // Handshake de Descubrimiento
    if (url === '/api/tags' || url === '/api/models' || url === '/v1/models') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            models: [{
                name: "Blackwell-RTX5080",
                model: "Blackwell-RTX5080",
                details: { family: "llama", format: "gguf" }
            }]
        }));
        return;
    }

    // Traduccion de Rutas
    if (url === '/api/chat') targetPath = '/v1/chat/completions';
    if (url === '/api/generate') targetPath = '/v1/completions';

    // Capturar Body para Agentic Search
    let bodyChunks = [];
    req.on('data', chunk => bodyChunks.push(chunk));
    req.on('end', async () => {
        let bodyBuffer = Buffer.concat(bodyChunks);
        let updatedBody = bodyBuffer;

        if (ENABLE_TAVILY && (url === '/api/chat' || url === '/api/generate')) {
            try {
                const bodyStr = bodyBuffer.toString();
                if (bodyStr) {
                    const jsonBody = JSON.parse(bodyStr);
                    let userQuery = "";

                    if (url === '/api/chat' && jsonBody.messages) {
                        userQuery = jsonBody.messages[jsonBody.messages.length - 1].content;
                        const evidence = await searchTavily(userQuery);
                        if (evidence) {
                            jsonBody.messages[jsonBody.messages.length - 1].content =
                                `### CONTEXTO DE INTERNET (SISTEMA BLACKWELL) ###\n${evidence}\n\n### INSTRUCCIÓN ###\nResponde a la siguiente pregunta usando los datos del contexto superior si son útiles.\n\nPregunta: ${userQuery}`;
                            updatedBody = Buffer.from(JSON.stringify(jsonBody));
                            console.log("[Shim] Contexto de internet inyectado con éxito.");
                        }
                    } else if (url === '/api/generate' && jsonBody.prompt) {
                        userQuery = jsonBody.prompt;
                        const evidence = await searchTavily(userQuery);
                        if (evidence) {
                            jsonBody.prompt = `### CONTEXTO DE INTERNET ###\n${evidence}\n\nTarea: ${userQuery}`;
                            updatedBody = Buffer.from(JSON.stringify(jsonBody));
                        }
                    }
                }
            } catch (e) {
                console.log("[Shim Error] Fallo al procesar búsqueda: " + e.message);
            }
        }


        // Forward a Llama-Server con limpieza de cabeceras
        const proxyReq = http.request({
            host: '127.0.0.1',
            port: TARGET_PORT,
            path: targetPath,
            method: req.method,
            headers: {
                'content-type': req.headers['content-type'] || 'application/json',
                'content-length': updatedBody.length,
                'accept': req.headers['accept'] || '*/*'
            }
        }, (proxyRes) => {
            if (url !== '/api/chat' && url !== '/api/generate') {
                res.writeHead(proxyRes.statusCode, proxyRes.headers);
                proxyRes.pipe(res);
                return;
            }

            res.writeHead(200, { 'Content-Type': 'application/x-ndjson' });
            proxyRes.on('data', (chunk) => {
                const lines = chunk.toString().split('\n');
                for (let line of lines) {
                    if (line.startsWith('data: ')) {
                        const dataStr = line.slice(6).trim();
                        if (dataStr === '[DONE]') continue;
                        try {
                            const json = JSON.parse(dataStr);
                            const choices = json.choices || [];
                            const content = (choices[0] && choices[0].delta && choices[0].delta.content) || "";
                            if (content) {
                                res.write(JSON.stringify({
                                    model: "Blackwell-RTX5080",
                                    message: { role: "assistant", content: content },
                                    done: false
                                }) + '\n');
                            }
                        } catch (e) { }
                    }
                }
            });
            proxyRes.on('end', () => {
                res.write(JSON.stringify({ done: true }) + '\n');
                res.end();
            });
        });

        proxyReq.on('error', (e) => {
            console.log("[Proxy Error] " + e.message);
            res.writeHead(502);
            res.end(JSON.stringify({ error: "Motor Blackwell no disponible", details: e.message }));
        });

        proxyReq.write(updatedBody);
        proxyReq.end();
    });
});


server.listen(PROXY_PORT, '0.0.0.0');
