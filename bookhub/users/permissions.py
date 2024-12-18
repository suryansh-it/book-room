
# we'll restrict book upload functionality to users with the "Admin"
# role and allow book reading for "Readers".

from rest_framework.permissions import BasePermission

class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.role == 'admin'

