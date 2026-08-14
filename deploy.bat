@echo off

aws s3 sync ./src s3://4kjax.com --delete && aws cloudfront create-invalidation --distribution-id E2MUFZM3OM0PIO --paths "/*"
aws cloudfront create-invalidation --distribution-id E2MUFZM3OM0PIO --paths "/*"

pause