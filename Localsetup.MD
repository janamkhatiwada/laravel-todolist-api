## Before running this you need this in local computer/server

Make sure you have the following installed:

- Docker & Docker Compose
- Git
- PHP Composer

## Local Setup Instructions

### 1. Clone the Repository

Clone the repository from GitHub:

```bash
git clone https://github.com/janamkhatiwada/laravel-todolist-api.git
cd laravel-todolist-api
```

### 2. Configure Environment

Copy the example environment file and adjust environment variables as needed:

```bash
cp .env.example .env
```

Update `.env` with the following configuration for Docker if not already setup here i have pushed a .env that works with docker-compose:

```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel_user
DB_PASSWORD=laravel_password

REDIS_HOST=redis
REDIS_PORT=6379
```

### 3. Build Docker Image

Build the Docker image to ensure the `app` service has all the necessary dependencies and configurations:

```bash
docker-compose build app
```

### 4. Install Composer Dependencies

Run Composer to install the necessary dependencies:

```bash
docker-compose run --rm app composer install
```

### 5. Generate Application Key

Run the following command to generate the application key:

```bash
docker-compose run --rm app php artisan key:generate
```

### 6. Run Migrations and Seed Database

Run the migrations to create the database tables and seed initial data:

```bash
docker-compose run --rm app php artisan migrate --seed
```

### 7. Start Docker Containers

Finally, start the Docker containers:

```bash
docker-compose up -d
```

This will start:

- `app`: The PHP application container.
- `webserver`: Nginx for serving the Laravel app.
- `db`: MySQL for database storage.
- `redis`: Redis for caching and queueing.

### 8. Access the Application

You should now be able to access the application at `http://localhost:8000`.