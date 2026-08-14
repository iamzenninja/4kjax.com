@echo off
aws s3 sync ./src s3://4kjax-com-prod-use1 --delete --region us-east-1
aws cloudfront create-invalidation --distribution-id E2MUFZM3OM0PIO --paths "/*"
echo "make sure no errors"
pause
git add -A
git commit -m "update"
git push