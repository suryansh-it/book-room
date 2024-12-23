from django.urls import path
from .views import RazorpayDonationView, RazorpayPaymentVerificationView

urlpatterns = [
    path('donate/', RazorpayDonationView.as_view(), name='donate'),
    path('verify-payment/', RazorpayPaymentVerificationView.as_view(), name='verify-payment'),
]
