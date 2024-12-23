import razorpay
from django.conf import settings
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Donation
from .serializers import DonationSerializer

class RazorpayDonationView(APIView):
    def post(self,request):
        user= request.user if request.user.is_authenticated else None
        amount = request.data.get('amount')

        if not amount :
            return Response({"error":"Amount is Required"},status=status.HTTP_400_BAD_REQUEST)
        
        try:
            #initialize Razorpay Client
            client = razorpay.Client(auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET))

            # Create Razorpay order
            razorpay_order = client.order.create({
                'amount':int(float(amount)*100), #convert to paise,
                'currency': 'INR',
                'payment_capture': '1',
            })

            # Save the order details in the database
            donation= Donation.objects.create(
                user=user,
                amount=amount,
                razorpay_order_id =razorpay_order['id']
            )

            return Response({
                'razorpay_order_id': razorpay_order['id'],
                'amount':amount,
                'currency':'INR'
            },status=status.HTTP_201_CREATED)
        

        except Exception as e:
            return Response({'error':str(e)},status=status.HTTP_500_INTERNAL_SERVER_ERROR)
