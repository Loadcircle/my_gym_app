To deploy the Cloud Function:

```bash
npm install   # If necessary
npm run build
firebase deploy --only functions
```

or


```bash
firebase deploy --only functions:functioName
```