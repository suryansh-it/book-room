from rest_framework import serializers
from .models import Donation

class DonationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Donation
        fields= ['id','amount','razorpay_order_id','razorpay_payment_id',"razorpay_signature",'status']
        read_only_fields= ['razorpay_order_id', 'razorpay_payment_id', 'razorpay_signature', 'status']