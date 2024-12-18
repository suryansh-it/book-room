from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework_simplejwt.tokens import RefreshToken
from .models import CustomUser
from .serializers import UserSerializer, LoginSerializer

#register views

class RegisterView(APIView):
    def post(self,request):
        serializer= UserSerializer(data= request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({'message': "user registered successfully"}, status = status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)   