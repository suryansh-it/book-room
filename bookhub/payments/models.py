from django.db import models
from django.conf import settings

class Donation(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete= models.CASCADE,null=True)
    amount= models.DecimalField(max_digits=10, decimal_places=2)
    razorpay_order_id= models.CharField(max_length=100,unique=True)
    razorpay_payment_id= models.CharField(max_length=100,blank=True, null=True)
    razorpay_signature= models.CharField(max_length=100,blank=True, null=True)
    status = models.CharField(max_length=20 , default='PENDING')        # PENDING, SUCCESS, FAILED
    created_at= models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Donation {self.id} - {self.status}"
