const { uploadFile } = require('../services/storage.service');

exports.uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const { folder } = req.body;
    const result = await uploadFile(req.file.buffer, req.file.originalname, folder);

    if (!result.success) {
      return res.status(500).json({ error: result.error });
    }

    res.json({
      url: result.url,
      simulated: result.simulated || false,
      message: 'Image uploaded successfully'
    });
  } catch (error) {
    console.error('Upload controller error:', error);
    res.status(500).json({ error: 'Internal server error during upload' });
  }
};
