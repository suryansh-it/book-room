
# we'll restrict book upload functionality to users with the "Author"
# role and allow book reading for "Readers".

from rest_framework.permissions import BasePermission

class IsAuthor(BasePermission):
    def has_permission(self, request, view):
        return request.user.role == 'author'
