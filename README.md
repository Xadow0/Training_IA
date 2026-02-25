# 🧠 TRAINING.IA

> **Aprende, Interactúa y Domina la IA Generativa.**
> Una aplicación multiplataforma diseñada para desmitificar la Inteligencia Artificial mediante educación interactiva y experimentación práctica.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

---

## 📖 Descripción del Proyecto

**TRAINING.IA** no es solo un chatbot; es una herramienta educativa integral. Nace de la necesidad de **divulgar y enseñar** el funcionamiento de las IAs generativas, promoviendo un uso seguro, eficiente y ético.

La aplicación combina un **Chat Avanzado** (con soporte para múltiples modelos) con un **Módulo de Aprendizaje Estructurado**, permitiendo a usuarios sin experiencia técnica comprender conceptos complejos como el *prompting*, la alucinación de la IA y el ajuste de contextos.

---

## ✨ Características Principales

### 🔋 IA Local "Zero-Config" 
* **Instalación Automática**: La app detecta si tu sistema necesita Ollama y lo instala automáticamente (Windows, macOS, Linux). 
* **Gestión de Modelos UI**: Descarga, actualiza y elimina modelos (como Phi-3, Mistral, Llama 3) directamente desde la interfaz de la aplicación. 
* **Privacidad Total**: Ejecuta la IA en tu dispositivo sin enviar datos a la nube.
### 🎓 Módulos de Aprendizaje Interactivo
Un recorrido educativo gamificado dividido en 5 niveles esenciales:
1.  **¿Cómo funciona la IA?**: Fundamentos de las IAs Generativas.
2.  **El arte del prompting**: Técnicas para comunicarse efectivamente.
3.  **Evaluar & Iterar**: Metodologías para refinar resultados.
4.  **Prompts avanzados**: Trucos de expertos y contextos complejos.
5.  **Ética y buenas prácticas**: Uso responsable, limitaciones y seguridad.

### 💬 Chat Multi-Modelo
Interfaz de chat unificada capaz de conectarse con diversos proveedores:
* **Nube**: Google Gemini (Google AI Studio) y OpenAI (ChatGPT).
* **Local (On-Device)**: Ejecución de modelos privados gestionados directamente por la app usando **Ollama**, sin necesidad de internet una vez instalados.
* **Servidor Privado**: Conexión a instancias remotas de Ollama (ej. Ubuntu Server vía Tailscale).

### 🛠️ Herramientas de Productividad
* **Gestor de Comandos**: Crea, organiza y reutiliza tus propios *prompts* y plantillas en carpetas personalizadas.
* **Historial Local**: Las conversaciones se guardan localmente en formato JSON y están encriptadas para mayor privacidad.
* **Sincronización**: (En desarrollo) Sincronización de progreso y comandos mediante Firebase.

---

## 🚀 Tecnologías y Arquitectura

El proyecto sigue una arquitectura limpia (**Clean Architecture**) para garantizar escalabilidad y mantenibilidad.

* **Framework**: Flutter (Dart)
* **Gestión de Estado**: Provider
* **Inyección de Dependencias**: GetIt
* **Backend / Auth**: Firebase Auth & Firestore
* **IA Local**: Integración nativa con Ollama
* **Almacenamiento Seguro**: Flutter Secure Storage & Shared Preferences
* **Encriptación**: Paquete `encrypt` para proteger el historial de chat.

### Estructura del Proyecto (`lib/`)
* `core/`: Configuraciones globales, constantes y utilidades.
* `features/`: Módulos funcionales desacoplados:
    * `auth/`: Autenticación de usuarios.
    * `chat/`: Lógica del chatbot, integración con APIs (Gemini, OpenAI, Ollama).
    * `commands/`: Gestión de comandos y carpetas de usuario.
    * `learning/`: Lógica y UI de los módulos educativos.
    * `settings/`: Gestión de API Keys y configuración de modelos.
    * `menu/`: Menú principal y navegación.

---

## ⚙️ Instalación y Configuración

### Prerrequisitos
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.9.2 o superior)
* Git
*  *(Opcional)* Claves API de Google Gemini o OpenAI si deseas usar modelos en la nube. **Para uso local no se requiere nada extra.**

### Pasos para ejecutar

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/Xadow0/chatbot_flutter.git](https://github.com/xadow0/chatbot_flutter.git)
    cd chatbot_flutter
    ```

2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```

3.  **Configurar Variables de Entorno (.env):**
    Crea un archivo `.env` en la raíz del proyecto (basado en el ejemplo si existe) para tus claves de API:
    ```env
    GEMINI_API_KEY=tu_clave_aqui
    OPENAI_API_KEY=tu_clave_aqui
    ```

4.  **Ejecutar la aplicación:**
    
    * **Escritorio (Windows/Linux/macOS):**
        ```bash
        flutter run -d windows  # o linux, macos
        ```
    * **Móvil (Android):**
        ```bash
        flutter run
        ```
5.	**Para compilar el ejecutable final (Windows, .exe)**
	```bash
	$ flutter build windows --release
	```

---

## 🧠 Uso de Modelos Locales 
**TRAINING.IA hace que la IA local sea accesible para todos.** 

1. Al abrir la aplicación, dirígete al chat y selecciona el proveedor **"Modelo Local"**. 
2. Si es la primera vez, la aplicación te guiará automáticamente para: 
	* Instalar los componentes necesarios en tu sistema. 
	* Descargar un modelo optimizado (por defecto `phi-3-mini`). 
1. ¡Listo! Ya puedes chatear con la IA sin conexión a internet. 

  Puedes gestionar tus modelos descargados en **Ajustes > Gestión de Modelos Locales**.

---

### 💾 Gestión del Historial de Conversaciones

Cada conversación se guarda automáticamente como un fichero .json de forma local, con la fecha y hora de la conversación, en la siguiente ruta:

```bash
Application/Documents/conversations/
```

---

## 🤝 Contribución

¡Las contribuciones son bienvenidas! Si deseas mejorar los módulos de aprendizaje o añadir soporte para nuevos proveedores de IA:

1.  Haz un Fork del proyecto.
2.  Crea una rama para tu característica (`git checkout -b feature/NuevaCaracteristica`).
3.  Haz Commit de tus cambios (`git commit -m 'Añadir nueva característica'`).
4.  Haz Push a la rama (`git push origin feature/NuevaCaracteristica`).
5.  Abre un Pull Request.

---

## 📄 License

This educational project is licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0).

You are free to:
- Share — copy and redistribute the material
- Adapt — remix, transform, and build upon the material
for any purpose, even commercially.

Under the following terms:
- Attribution — You must give appropriate credit to the author.

© 2026 Leonardo Sánchez Ferrer

---

> _Creado por xadow0_
