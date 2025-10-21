# MinIO S3 Storage Setup for Quizzy

## Overview

Quizzy uses MinIO for S3-compatible object storage with **Bun's native S3 API** (zero npm dependencies). This guide covers setup, configuration, and usage.

---

## 🚀 Quick Start

### 1. Start MinIO Container

```bash
cd backend
docker-compose up -d minio
```

MinIO will be available at:
- **API**: http://localhost:9000
- **Console**: http://localhost:9001

### 2. Create Bucket

**Option A: Via Console (Recommended)**
1. Open http://localhost:9001
2. Login with:
   - Username: `minioadmin`
   - Password: `minioadmin123`
3. Click "Buckets" → "Create Bucket"
4. Bucket name: `quizzy-images`
5. Click "Create"

**Option B: Via mc CLI**
```bash
mc alias set local http://localhost:9000 minioadmin minioadmin123
mc mb local/quizzy-images
```

### 3. Environment Variables

Already configured in `.env`:
```env
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=minioadmin123
S3_BUCKET=quizzy-images
```

---

## 📤 Image Upload API

### Upload Image
```http
POST /api/upload/image
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
- image: File (max 5MB, jpeg/png/webp/gif)
```

**Example with curl:**
```bash
curl -X POST http://localhost:8000/api/upload/image \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/image.jpg"
```

**Response:**
```json
{
  "success": true,
  "image": {
    "id": "uuid",
    "filename": "uuid.jpg",
    "url": "presigned-url-valid-24h"
  }
}
```

---

### Get Presigned URL
```http
GET /api/upload/image/:id/url
Authorization: Bearer {token}
```

**Response:**
```json
{
  "url": "https://localhost:9000/quizzy-images/uuid.jpg?..."
}
```

URL valid for 1 hour.

---

### Download Image (Stream)
```http
GET /api/upload/image/:id/download
```

Streams image directly. Public endpoint (no auth required).

---

### List User Images
```http
GET /api/upload/images?limit=20&offset=0
Authorization: Bearer {token}
```

**Response:**
```json
{
  "images": [
    {
      "id": "uuid",
      "userId": "uuid",
      "filename": "uuid.jpg",
      "originalName": "photo.jpg",
      "mimeType": "image/jpeg",
      "size": 524288,
      "bucket": "quizzy-images",
      "createdAt": "2025-01-20T...",
      "updatedAt": "2025-01-20T..."
    }
  ]
}
```

---

### Delete Image
```http
DELETE /api/upload/image/:id
Authorization: Bearer {token}
```

Deletes from both S3 and database. Only owner can delete.

**Response:**
```json
{
  "success": true,
  "message": "Image deleted"
}
```

---

## 🎯 Integration Examples

### Profile Picture Upload (Flutter)

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

Future<String?> uploadProfilePicture(File imageFile, String token) async {
  // 1. Upload image to S3
  final uploadUri = Uri.parse('$baseUrl/api/upload/image');
  final uploadRequest = http.MultipartRequest('POST', uploadUri);
  uploadRequest.headers['Authorization'] = 'Bearer $token';
  uploadRequest.files.add(
    await http.MultipartFile.fromPath('image', imageFile.path)
  );
  
  final uploadResponse = await uploadRequest.send();
  final uploadData = await uploadResponse.stream.bytesToString();
  final uploadJson = jsonDecode(uploadData);
  
  if (uploadResponse.statusCode != 201) {
    throw Exception('Upload failed');
  }
  
  final imageUrl = uploadJson['image']['url'];
  
  // 2. Update profile with image URL
  final profileUri = Uri.parse('$baseUrl/api/user/profile/picture');
  final profileResponse = await http.put(
    profileUri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'profilePictureUrl': imageUrl}),
  );
  
  if (profileResponse.statusCode == 200) {
    return imageUrl;
  }
  
  return null;
}
```

### Post Image Upload (Flutter)

```dart
Future<void> createPostWithImage(File imageFile, String text, String token) async {
  // 1. Upload image
  final uploadUri = Uri.parse('$baseUrl/api/upload/image');
  final uploadRequest = http.MultipartRequest('POST', uploadUri);
  uploadRequest.headers['Authorization'] = 'Bearer $token';
  uploadRequest.files.add(
    await http.MultipartFile.fromPath('image', imageFile.path)
  );
  
  final uploadResponse = await uploadRequest.send();
  final uploadData = await uploadResponse.stream.bytesToString();
  final uploadJson = jsonDecode(uploadData);
  
  final imageUrl = uploadJson['image']['url'];
  
  // 2. Create post with image URL
  final postUri = Uri.parse('$baseUrl/api/social/posts');
  await http.post(
    postUri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'text': text,
      'postType': 'image',
      'imageUrl': imageUrl,
    }),
  );
}
```

---

## 🔐 Security Features

### File Validation
- **Max size**: 5MB
- **Allowed types**: JPEG, PNG, WebP, GIF
- **Unique filenames**: UUID-based to prevent conflicts

### Access Control
- Upload requires authentication
- Delete requires ownership verification
- Presigned URLs expire (1-24 hours)

### Database Tracking
All uploaded images are tracked in PostgreSQL:
- Owner (userId)
- Original filename
- File metadata (size, type)
- Timestamps

---

## 🛠️ Bun Native S3 Features Used

### Zero Dependencies
No npm packages needed - uses Bun's built-in `s3` module:
```typescript
import { s3 } from 'bun'
```

### Synchronous Presigning
```typescript
const url = s3File.presign({ expiresIn: 3600 })  // No await!
```

### Automatic Environment Loading
```typescript
// Reads S3_* variables automatically
const file = s3.file('image.jpg')
```

### Streaming Support
```typescript
const stream = s3File.stream()
return new Response(stream)
```

---

## 📊 Database Schema

### images Table
```sql
CREATE TABLE images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  filename TEXT NOT NULL UNIQUE,
  original_name TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size INTEGER NOT NULL,
  bucket TEXT NOT NULL DEFAULT 'quizzy-images',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX images_user_id_idx ON images(user_id);
CREATE INDEX images_filename_idx ON images(filename);
CREATE INDEX images_created_at_idx ON images(created_at);
```

---

## 🐳 Docker Configuration

```yaml
minio:
  image: minio/minio
  container_name: quizzy-minio
  ports:
    - "9000:9000"  # API
    - "9001:9001"  # Console
  environment:
    MINIO_ROOT_USER: minioadmin
    MINIO_ROOT_PASSWORD: minioadmin123
  command: server /data --console-address ":9001"
  volumes:
    - minio_data:/data
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
    interval: 30s
    timeout: 10s
    retries: 3
```

---

## 🔧 Troubleshooting

### MinIO Container Won't Start
```bash
# Check logs
docker-compose logs minio

# Restart container
docker-compose restart minio
```

### Bucket Not Found Error
1. Verify bucket exists: http://localhost:9001
2. Check bucket name matches `S3_BUCKET` in `.env`
3. Recreate bucket if needed

### Upload Fails with 403
1. Check S3 credentials in `.env`
2. Verify MinIO container is running
3. Ensure bucket permissions are correct

### Presigned URL Expired
Presigned URLs are temporary:
- Upload response: 24 hours
- URL endpoint: 1 hour
- Regenerate as needed

---

## 📚 Additional Resources

- **Bun S3 Docs**: https://bun.sh/docs/api/s3
- **MinIO Docs**: https://min.io/docs/minio/linux/index.html
- **Hono File Upload**: https://hono.dev/examples/file-upload
