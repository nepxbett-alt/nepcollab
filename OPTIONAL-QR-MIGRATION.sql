-- NepCollab optional manual QR payment mode.
-- Keep disabled for the free launch.

update platform_settings set value='false' where key='payment_enabled';
update platform_settings set value='0' where key='platform_fee_npr';
update platform_settings set value='' where key='payment_qr_url';

-- Later, when ready to enable the fee:
-- update platform_settings set value='true' where key='payment_enabled';
-- update platform_settings set value='YOUR_FEE' where key='platform_fee_npr';
-- update platform_settings set value='YOUR_QR_IMAGE_URL' where key='payment_qr_url';
