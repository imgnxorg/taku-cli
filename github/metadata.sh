mkdir -p ./.github/workflows
touch ./.github/workflows/docker-publish.yml

echo '
name: Build and Push Docker Image

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repo
        uses: actions/checkout@v3

      - name: Log in to GHCR
        run: echo "${{ secrets.GHCR_PAT }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

      - name: Build Docker image
        run: |
          docker build -t ghcr.io/${{ github.actor }}/my-app:latest .
      - name: Push Docker image
        run: |
          docker push ghcr.io/${{ github.actor }}/my-app:latest

      - name: Auto-Link Package to Repo
        run: |
          gh api -X PATCH "https://api.github.com/orgs/imgnx/packages/container/my-next-app" \
          -f repository="imgnx/my-next-app"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
' >./.github/workflows/docker-publish.yml
