import { supabase } from '../config/supabase';
import * as ImagePicker from 'expo-image-picker';

export class StorageService {
  private bucketName = 'profile-photos';

  async requestPermissions() {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') {
      throw new Error('Permission to access media library was denied');
    }
    return status;
  }

  async pickImage() {
    await this.requestPermissions();

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [4, 5],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      return result.assets[0].uri;
    }

    return null;
  }

  async takePhoto() {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      throw new Error('Permission to access camera was denied');
    }

    const result = await ImagePicker.launchCameraAsync({
      allowsEditing: true,
      aspect: [4, 5],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      return result.assets[0].uri;
    }

    return null;
  }

  async uploadImage(uri: string, userId: string): Promise<string> {
    try {
      // Convert URI to blob
      const response = await fetch(uri);
      const blob = await response.blob();

      // Create unique filename
      const fileExt = uri.split('.').pop();
      const fileName = `${userId}/${Date.now()}.${fileExt}`;

      // Upload to Supabase Storage
      const { data, error } = await supabase.storage
        .from(this.bucketName)
        .upload(fileName, blob, {
          contentType: `image/${fileExt}`,
          upsert: false,
        });

      if (error) throw error;

      // Get public URL
      const { data: urlData } = supabase.storage
        .from(this.bucketName)
        .getPublicUrl(fileName);

      return urlData.publicUrl;
    } catch (error) {
      console.error('Upload error:', error);
      throw error;
    }
  }

  async deleteImage(url: string) {
    try {
      // Extract file path from URL
      const urlParts = url.split('/');
      const fileName = urlParts.slice(-2).join('/'); // userId/timestamp.ext

      const { error } = await supabase.storage
        .from(this.bucketName)
        .remove([fileName]);

      if (error) throw error;
    } catch (error) {
      console.error('Delete error:', error);
      throw error;
    }
  }

  async uploadMultipleImages(uris: string[], userId: string): Promise<string[]> {
    const uploadPromises = uris.map((uri) => this.uploadImage(uri, userId));
    return Promise.all(uploadPromises);
  }
}

export const storageService = new StorageService();
