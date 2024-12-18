from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager


# we will create a custom user model to have more flexibility
# (like adding roles) and customize the fields.

#custom user manager
class CustomUserManager(BaseUserManager):
    def create_user(self,email, password = None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        extra_fields.setdefault('is_active', True)
        user= self.model(email=email,**extra_fields)
        user.set_password(password)
        user.save(using= self._db)
        return user
    

    def create_superuser(self, email, password= None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email,password,**extra_fields)
    

# Custom User Model
class CustomUser(AbstractUser):
    ROLE_CHOICES = [
        ('reader', 'Reader'),
        
        ('admin', 'Admin'),
    ]
    username = None  # Remove username as an identifier
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='reader')

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    objects = CustomUserManager()

    def __str__(self):
        return self.email
        
