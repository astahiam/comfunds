/**
 * API Service
 * Centralized API client for backend communication
 */

import axios, {AxiosInstance, AxiosError} from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {Config} from '../constants/Config';
import {ApiResponse} from '../types';

class ApiService {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: Config.API_BASE_URL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.client.interceptors.request.use(
      async config => {
        const token = await AsyncStorage.getItem('auth_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      error => {
        return Promise.reject(error);
      },
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      response => response,
      async error => {
        if (error.response?.status === 401) {
          // Token expired or invalid
          await AsyncStorage.removeItem('auth_token');
          await AsyncStorage.removeItem('user');
        }
        return Promise.reject(error);
      },
    );
  }

  // Auth endpoints
  async login(email: string, password: string): Promise<ApiResponse<any>> {
    const response = await this.client.post('/auth/login', {
      email,
      password,
    });
    return response.data;
  }

  async register(userData: any): Promise<ApiResponse<any>> {
    const response = await this.client.post('/auth/register', userData);
    return response.data;
  }

  // User endpoints
  async getUsers(params?: any): Promise<ApiResponse<any[]>> {
    const response = await this.client.get('/users', {params});
    return response.data;
  }

  async getUserById(id: string): Promise<ApiResponse<any>> {
    const response = await this.client.get(`/users/${id}`);
    return response.data;
  }

  async updateUser(id: string, data: any): Promise<ApiResponse<any>> {
    const response = await this.client.put(`/users/${id}`, data);
    return response.data;
  }

  // Cooperative endpoints
  async getCooperatives(params?: any): Promise<ApiResponse<any[]>> {
    const response = await this.client.get('/cooperatives', {params});
    return response.data;
  }

  async getCooperativeById(id: string): Promise<ApiResponse<any>> {
    const response = await this.client.get(`/cooperatives/${id}`);
    return response.data;
  }

  // Business endpoints
  async getBusinesses(params?: any): Promise<ApiResponse<any[]>> {
    const response = await this.client.get('/businesses', {params});
    return response.data;
  }

  async getBusinessById(id: string): Promise<ApiResponse<any>> {
    const response = await this.client.get(`/businesses/${id}`);
    return response.data;
  }

  async createBusiness(data: FormData): Promise<ApiResponse<any>> {
    const response = await this.client.post('/businesses', data, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  }

  async updateBusiness(id: string, data: FormData): Promise<ApiResponse<any>> {
    const response = await this.client.put(`/businesses/${id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  }

  // Project endpoints
  async getProjects(params?: any): Promise<ApiResponse<any[]>> {
    const response = await this.client.get('/projects', {params});
    return response.data;
  }

  async getProjectById(id: string): Promise<ApiResponse<any>> {
    const response = await this.client.get(`/projects/${id}`);
    return response.data;
  }

  async createProject(data: any): Promise<ApiResponse<any>> {
    const response = await this.client.post('/projects', data);
    return response.data;
  }

  async updateProject(id: string, data: any): Promise<ApiResponse<any>> {
    const response = await this.client.put(`/projects/${id}`, data);
    return response.data;
  }

  // Investment endpoints
  async getInvestments(params?: any): Promise<ApiResponse<any[]>> {
    const response = await this.client.get('/investments', {params});
    return response.data;
  }

  async getInvestmentById(id: string): Promise<ApiResponse<any>> {
    const response = await this.client.get(`/investments/${id}`);
    return response.data;
  }

  async createInvestment(data: any): Promise<ApiResponse<any>> {
    const response = await this.client.post('/investments', data);
    return response.data;
  }

  async getInvestorPortfolio(investorId: string): Promise<ApiResponse<any[]>> {
    const response = await this.client.get(`/investments/investor/${investorId}`);
    return response.data;
  }

  // Upload endpoints
  async uploadBusinessDocument(
    file: any,
    documentType: string,
  ): Promise<ApiResponse<any>> {
    const formData = new FormData();
    formData.append('file', {
      uri: file.uri,
      type: file.type,
      name: file.fileName || 'document.pdf',
    } as any);
    formData.append('document_type', documentType);

    const response = await this.client.post(
      '/upload/business-document',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      },
    );
    return response.data;
  }
}

export default new ApiService();

