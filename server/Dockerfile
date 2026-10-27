FROM dart:stable
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o server
# Mount a persistent volume at /app/uploads or files are lost on redeploy
CMD ["./server"]
