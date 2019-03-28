set -e
bundle exec rdoc
npm run build --prefix docs
npm run deploy --prefix docs