const express = require('express');
const router = express.Router();
const multer = require('multer');
const documentController = require('../controllers/document.controller');

const ACCEPTED_MIMES = new Set([
  'application/pdf',
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/webp',
]);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (req, file, cb) => {
    if (ACCEPTED_MIMES.has(file.mimetype)) return cb(null, true);
    cb(new Error('Only PDF or image files are allowed'), false);
  },
});

router.get('/', documentController.listDocuments);
router.get('/:id', documentController.getDocument);
router.post('/upload', upload.single('file'), documentController.uploadDocument);
router.post('/generate-lease', documentController.generateLease);
router.post('/generate-receipt', documentController.generateReceipt);
router.delete('/:id', documentController.deleteDocument);

module.exports = router;
