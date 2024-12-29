from django.contrib import admin
from .models import CustomUser

# Register your CustomUser model to appear in the Django Admin panel
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ('email', 'role', 'is_staff', 'is_active')  # Display relevant fields
    search_fields = ('email', 'role')  # Allow searching by email and role
    list_filter = ('is_staff', 'is_active')  # Filter by staff or active status

admin.site.register(CustomUser, CustomUserAdmin)
