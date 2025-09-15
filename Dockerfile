# Usar una imagen base de Dart
FROM dart:stable AS build

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar los archivos de la aplicación al contenedor
COPY . .

# Obtener las dependencias de Dart
RUN dart pub get

# Exponer el puerto en el que la aplicación escuchará
EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["dart", "bin/server.dart"]
