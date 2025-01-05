function services_update {
    echo "Enabling services"
    # Include here all the necessary changes to services
    sudo systemctl enable aa-proxy.service
    sudo systemctl enable aa-usbgadget.service
}