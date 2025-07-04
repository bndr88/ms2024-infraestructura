<?php
$consulUrl = 'http://consul-server:8500';
$consulUrlServices = 'http://consul-server:8500/v1/catalog/services';
$kongUrl = 'http://kong:8001';

function esperarServicio($nombre, $url, $esperarFn) {
    echo "⏳ Esperando que $nombre esté disponible en $url...\n";
    while (true) {
        $resultado = @file_get_contents($url);
        if ($resultado) {
            // echo "🪵 Respuesta de $nombre:\n$resultado\n";

            if ($esperarFn($resultado)) {
                echo "✅ $nombre disponible.\n";
                break;
            } else {
                echo "❌ $nombre respondió pero no está listo aún.\n";
            }
        } else {
            echo "🔁 Sin respuesta de $nombre. Reintentando...\n";
        }
        sleep(3);
    }
}

// Esperar a Consul
esperarServicio("Consul", "$consulUrlServices", function ($r) {
    return json_decode($r, true) !== null;
});

// Esperar a Kong
esperarServicio("Kong", "$kongUrl/status", function ($r) {
    $data = json_decode($r, true);
    echo 'Datos::'.$data;
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo "❌ Error al decodificar JSON de Kong: " . json_last_error_msg() . "\n";
        return false;
    }
    return isset($data['database']['reachable'])=== true;
});

echo "🚀 Iniciando sincronización Consul -> Kong...\n";

$services = json_decode(file_get_contents($consulUrlServices), true);

if (!$services) {
    die("[!] No se pudieron obtener servicios desde Consul\n");
}

foreach ($services as $serviceName => $tags) {
    echo "➡️ Procesando servicio: $serviceName\n";

    $instances = json_decode(file_get_contents("http://consul-server:8500/v1/catalog/service/$serviceName"), true);
    if (empty($instances)) {
        echo "⚠️  Sin instancias para $serviceName, omitiendo...\n";
        continue;
    }

    $instance = $instances[0];
    $host = $instance['ServiceAddress'] ?: $instance['Address'];
    //$host = "host.docker.internal";
    $port = $instance['ServicePort'];
    $serviceUrl = "http://$host:$port";

    if (!servicioConsulHealthy($consulUrl, $serviceName)) {
        echo "❌ Servicio '$serviceName' no está healthy en Consul. Eliminando rutas y servicio en Kong...\n";
        eliminarRutasAsociadas($kongUrl, $serviceName);
        eliminarServicioKong($kongUrl, $serviceName);
        continue; // saltar al siguiente servicio
    }
    
    gestionarServicios($kongUrl,$serviceName,$serviceUrl);

    $routeName = "ruta-$serviceName";
    $paths = ["/$serviceName"];

    gestionarRuta($kongUrl, $routeName, $serviceName, $paths);
   
}

function servicioExiste($kongUrl,$serviceName):int{
    $checkCh = curl_init("$kongUrl/services/$serviceName");
    curl_setopt_array($checkCh, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'GET'
    ]);
    $checkResponse = curl_exec($checkCh);
    $httpCode = curl_getinfo($checkCh, CURLINFO_HTTP_CODE);
    curl_close($checkCh);
    return $httpCode;
}

function crearServicio($kongUrl, $serviceName, $serviceUrl) : int {
    $servicePayload = [
        'name' => $serviceName,
        'url' => $serviceUrl
    ];

    $ch = curl_init("$kongUrl/services");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($servicePayload)
    ]);
    curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return $httpCode;  
}

function actualizarServicio($kongUrl, $serviceName, $serviceUrl): int {
    $payload = [
        'name' => $serviceName,
        'url' => $serviceUrl
    ];

    $ch = curl_init("$kongUrl/services/$serviceName");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'PATCH',
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload)
    ]);
    curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return $httpCode;
}

function gestionarServicios($kongUrl, $serviceName,$serviceUrl) : void {
    $httpCode = servicioExiste($kongUrl, $serviceName);

    // Si no existe (404), lo creamos
    if ($httpCode === 404) {
        $respuesta = crearServicio($kongUrl, $serviceName, $serviceUrl);
        if ($respuesta >= 200 && $respuesta < 300) {
            echo "✅ Servicio creado: $serviceName su url es:$serviceUrl \n";
            agregarPluginJWT($kongUrl, $serviceName);
        } else {
            echo "❌ Error al crear el servicio. Código HTTP: $respuesta\n";
        }
    } elseif ($httpCode === 200) {
        // Ya existe, intentamos actualizar
        $respuesta = actualizarServicio($kongUrl, $serviceName, $serviceUrl);
        if ($respuesta >= 200 && $respuesta < 300) {
            echo "🔄 Servicio actualizado: $serviceName su url es:$serviceUrl \n";
            agregarPluginJWT($kongUrl, $serviceName);
        } else {
            echo "❌ Error al actualizar el servicio. Código HTTP: $respuesta\n";
        }
    } else {
        echo "⚠️ Error inesperado al verificar el servicio '$serviceName'. Código HTTP: $httpCode\n";
    }
}

function rutaExiste($kongUrl, $routeName): int {
    $ch = curl_init("$kongUrl/routes/$routeName");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'GET'
    ]);
    curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return $httpCode;
}

function crearRuta($kongUrl, $routeName, $serviceName, $paths): int {
    $payload = [
        'name' => $routeName,
        'paths' => $paths, // ejemplo: ['/evaluacion']
        'strip_path' => true,
        'service' => ['name' => $serviceName]
    ];

    $ch = curl_init("$kongUrl/routes");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload)
    ]);
    curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return $httpCode;
}

function actualizarRuta($kongUrl, $routeName, $paths): int {
    $payload = [
        'paths' => $paths,
        'strip_path' => true
    ];

    $ch = curl_init("$kongUrl/routes/$routeName");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'PATCH',
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload)
    ]);
    curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return $httpCode;
}

function gestionarRuta($kongUrl, $routeName, $serviceName, $paths): void {
    $httpCode = rutaExiste($kongUrl, $routeName);

    if ($httpCode === 404) {
        $respuesta = crearRuta($kongUrl, $routeName, $serviceName, $paths);
        if ($respuesta >= 200 && $respuesta < 300) {
            echo "✅ Ruta creada: $routeName → ".implode(', ', $paths)."\n";
        } else {
            echo "❌ Error al crear la ruta. Código HTTP: $respuesta\n";
        }
    } elseif ($httpCode === 200) {
        $respuesta = actualizarRuta($kongUrl, $routeName, $paths);
        if ($respuesta >= 200 && $respuesta < 300) {
            echo "🔄 Ruta actualizada: $routeName → ".implode(', ', $paths)."\n";
        } else {
            echo "❌ Error al actualizar la ruta. Código HTTP: $respuesta\n";
        }
    } else {
        echo "⚠️ Error inesperado al verificar la ruta '$routeName'. Código HTTP: $httpCode\n";
    }
}

function pluginJWTExiste($kongUrl, $serviceName): bool {
    $ch = curl_init("$kongUrl/services/$serviceName/plugins?name=jwt");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'GET'
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $data = json_decode($response, true);
        return !empty($data['data']);
    }

    return false;
}

function agregarPluginJWT($kongUrl, $serviceName): void {
    if ($serviceName === 'identidad') {
        return;
    }
    if (pluginJWTExiste($kongUrl, $serviceName)) {
        echo "🔐 El plugin JWT ya está habilitado en el servicio '$serviceName'.\n";
        return;
    }

    $ch = curl_init("$kongUrl/services/$serviceName/plugins");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query(['name' => 'jwt'])
    ]);
    curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode >= 200 && $httpCode < 300) {
        echo "🔐 Plugin JWT habilitado para el servicio '$serviceName'.\n";
    } else {
        echo "❌ Error al habilitar el plugin JWT en '$serviceName'. Código HTTP: $httpCode\n";
    }
}

function servicioConsulHealthy($consulUrl, $serviceName): bool {
    $ch = curl_init("$consulUrl/v1/health/checks/$serviceName");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'GET'
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $data = json_decode($response, true);
        foreach ($data as $check) {
            if ($check['Status'] !== 'passing') {
                return false;
            }
        }
        return true;
    }

    return false;
}

function eliminarServicioKong($kongUrl, $serviceName): void {
    $ch = curl_init("$kongUrl/services/$serviceName");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'DELETE'
    ]);
    $respuesta = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 204) {
        echo "🗑️ Servicio eliminado de Kong: $serviceName\n";
    } elseif ($httpCode === 404) {
        echo "ℹ️ Servicio '$serviceName' no estaba registrado en Kong.\n";
    } else {
        echo "❌ Error al eliminar '$serviceName' de Kong. Código HTTP: $httpCode respuesta: $respuesta \n";
    }
}

function obtenerServiceId($kongUrl, $serviceName): ?string {
    $ch = curl_init("$kongUrl/services/$serviceName");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'GET'
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $data = json_decode($response, true);
        return $data['id'] ?? null;
    }

    return null;
}

function eliminarRutasAsociadas($kongUrl, $serviceName): void {
    $serviceId = obtenerServiceId($kongUrl, $serviceName);
    if (!$serviceId) {
        echo "⚠️ No se pudo obtener el ID del servicio '$serviceName'. No se eliminarán rutas.\n";
        return;
    }

    $ch = curl_init("$kongUrl/routes?size=1000");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'GET'
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        echo "❌ Error al obtener rutas para '$serviceName'. Código: $httpCode\n";
        return;
    }

    $data = json_decode($response, true);
    foreach ($data['data'] ?? [] as $route) {
        if (isset($route['service']['id']) && $route['service']['id'] === $serviceId) {
            $routeId = $route['id'];
            $deleteCh = curl_init("$kongUrl/routes/$routeId");
            curl_setopt_array($deleteCh, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CUSTOMREQUEST => 'DELETE'
            ]);
            curl_exec($deleteCh);
            $delCode = curl_getinfo($deleteCh, CURLINFO_HTTP_CODE);
            curl_close($deleteCh);

            if ($delCode === 204) {
                echo "🗑️ Ruta eliminada: {$route['name'] } (ID: $routeId)\n";
            } else {
                echo "❌ Error al eliminar ruta (ID: $routeId). Código: $delCode\n";
            }
        }
    }
}

