const firebase = require('../config/firebase');

async function uploadFile(fileBuffer, fileName, folder = 'maintenance') {
  try {
    if (!firebase.apps.length || !process.env.FIREBASE_STORAGE_BUCKET) {
      console.warn('Firebase Storage not configured, simulating upload');
      return {
        success: true,
        url: `https://storage.googleapis.com/simulated-bucket/${folder}/${Date.now()}_${fileName}`,
        simulated: true
      };
    }

    const bucket = firebase.storage().bucket(process.env.FIREBASE_STORAGE_BUCKET);
    const file = bucket.file(`${folder}/${Date.now()}_${fileName}`);

    await file.save(fileBuffer, {
      metadata: { contentType: 'auto' },
      public: true
    });

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${file.name}`;
    return { success: true, url: publicUrl };
  } catch (error) {
    console.error('File upload failed:', error.message);
    return { success: false, error: 'Failed to upload file' };
  }
}

async function deleteFile(fileUrl) {
  try {
    if (!firebase.apps.length || !process.env.FIREBASE_STORAGE_BUCKET) return { success: true, simulated: true };

    const bucket = firebase.storage().bucket(process.env.FIREBASE_STORAGE_BUCKET);
    const fileName = fileUrl.split(`${bucket.name}/`)[1];
    if (fileName) {
      await bucket.file(fileName).delete();
    }
    return { success: true };
  } catch (error) {
    console.error('File deletion failed:', error.message);
    return { success: false, error: 'Failed to delete file' };
  }
}

module.exports = { uploadFile, deleteFile };
