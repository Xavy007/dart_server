# Usar la imagen base de Dart
FROM dart:stable AS build

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar los archivos al contenedor
COPY . .

# Obtener las dependencias del proyecto
RUN dart pub get

# Exponer el puerto que se usará en el contenedor
EXPOSE 3000

# Comando para ejecutar el servidor
CMD ["dart", "bin/server.dart"]
