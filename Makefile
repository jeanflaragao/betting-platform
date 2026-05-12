up:
	cd infra/compose && docker compose up -d

down:
	cd infra/compose && docker compose down

logs:
	cd infra/compose && docker compose logs -f

migrate:
	cd backend && bin/rails db:prepare && RAILS_ENV=test bin/rails db:prepare