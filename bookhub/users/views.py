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
        # Deserialize the request data using UserSerializer
        serializer= UserSerializer(data= request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({'message': "user registered successfully"}, status = status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)   
    

# Login View
class LoginView(APIView):
    def post(self, request):
        # Deserialize the request data using LoginSerializer
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            password = serializer.validated_data['password']
            try:
                user= CustomUser.objects.get(email=email)
            except CustomUser.DoesNotExist:
                return Response({"error":"Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)
            

            # Check if the password is correct
            if user.check_password(password):
                refresh = RefreshToken.for_user(user)    # Generate JWT tokens
                return Response({
                    'refresh':str(refresh),              # Return refresh token
                    'access':str(refresh.access_token),     # Return access token
                })
            
            return Response({'error': "invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)