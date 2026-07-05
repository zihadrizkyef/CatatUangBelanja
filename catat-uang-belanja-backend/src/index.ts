import 'dotenv/config';

import { app } from './app';

const port = process.env.PORT ? Number(process.env.PORT) : 3000;

app.listen(port, () => {
  console.log(`catat-uang-belanja-backend listening on port ${port}`);
});
