echo "🔄 Resetting data..."
docker compose exec laravel-api php artisan migrate:fresh --seed