# Artesanías Inti - Ecosistema Digital 🏺

Este repositorio contiene la solución integral para la gestión y venta de productos de Artesanías Inti.

## 🚀 Componentes del Sistema

1.  **Tienda Web (Storefront)**:
    *   Interfaz profesional para clientes inspirada en Mercado Libre.
    *   **Link**: [https://cruz-star.github.io/artesanias-inti/](https://cruz-star.github.io/artesanias-inti/)

2.  **App del Vendedor (Mobile)**:
    *   Aplicación Flutter para gestionar inventario, pedidos y sincronizar con la web.
    *   Incluye sistema de autodescubrimiento dinámico del servidor.

3.  **Server Manager (Multiplataforma)**:
    *   El "corazón" del sistema. Gestiona la base de datos local (JSON), la API y la sincronización con GitHub.
    *   Muestra el estado de conexión de la App y la Web en tiempo real.

## 📲 Descargas (APK)

Puedes encontrar los instaladores actualizados en la raíz de este repositorio:
*   [App_Vendedor.apk](./App_Vendedor.apk)
*   [Server_Manager.apk](./Server_Manager.apk)

## 🛠️ Sistema de Autodescubrimiento

No necesitas configurar IPs manualmente. 
1.  Enciende el **Server Manager**.
2.  El servidor publicará su IP actual en `config.json`.
3.  Tanto la App como la Web buscarán esta IP automáticamente para conectarse.

---
© 2026 Artesanías Inti - Todos los derechos reservados.
