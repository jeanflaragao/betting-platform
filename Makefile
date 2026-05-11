up:
	cd infra/compose && docker compose up -d

down:
	cd infra/compose && docker compose down

logs:
	cd infra/compose && docker compose logs -f