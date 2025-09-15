# Usar la imagen base de Dart
FROM dart:stable AS build

# Instalar libsqlite3
RUN apt-get update && apt-get install -y libsqlite3-dev

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar los archivos del proyecto al contenedor
COPY . .

# Obtener las dependencias del proyecto
RUN dart pub get

# Exponer el puerto que la aplicación escuchará
EXPOSE 3000

# Comando para ejecutar el servidor
CMD ["dart", "bin/server.dart"]
