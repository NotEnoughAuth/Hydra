#!/bin/bash
# Basic UI for controlling the hydra network and enabling/removing services
WEB=false
EMAIL=false
DNS=false
SPLUNK=false
ECOMMERCE=false


# Check if environment variables are set
# if [ -z "$SERVICE_IP" ] || [ -z "$INTERNAL_IP" ]; then
#     echo "You have not installed the hydra network. Please run the createHydra.sh script first."
#     exit 1
# fi


enableEcommerce() {
    # Deploy the ecommerce application to the cluster with a yaml file
    # We are using the same container registry that was created in the createHydra.sh script
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce
  namespace: default
spec:
    replicas: 3
    selector:
        matchLabels:
        app: ecommerce
    template:
        metadata:
        labels:
            app: ecommerce
        spec:
        containers:
        - name: ecommerce
            image: $INTERNAL_IP:5000/ecommerce:latest
            ports:
            - containerPort: 80
            - containerPort: 443
EOF
# Expose the ecommerce application to the internal metallb ip address
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ecommerce
  namespace: default
spec:
    type: LoadBalancer
    selector:
        app: ecommerce
    ports:
    - protocol: TCP
      port: 80
      targetPort: 80
    - protocol: TCP
        port: 443
        targetPort: 443
    loadBalancerIP: $SERVICE_IP
EOF
}

removeEcommerce() {
    # Remove the ecommerce application from the cluster
    kubectl delete deployment ecommerce
    kubectl delete service ecommerce
}

enableSplunk() {
    # Deploy the splunk application to the cluster with a yaml file
    # We are using the same container registry that was created in the createHydra.sh script
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: splunk
  namespace: default
spec:
    replicas: 3
    selector:
        matchLabels:
        app: splunk
    template:
        metadata:
        labels:
            app: splunk
        spec:
        containers:
        - name: splunk
            image: $INTERNAL_IP:5000/splunk:latest
            ports:
            - containerPort: 8000
EOF
# Expose the splunk application to the internal metallb ip address
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: splunk
  namespace: default
spec:
    type: LoadBalancer
    selector:
        app: splunk
    ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
    loadBalancerIP: $SERVICE_IP
EOF
}

removeSplunk() {
    # Remove the splunk application from the cluster
    kubectl delete deployment splunk
    kubectl delete service splunk
}

enableEmail() {
    # Deploy the email application to the cluster with a yaml file
    # We are using the same container registry that was created in the createHydra.sh script
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: email
  namespace: default
spec:
    replicas: 3
    selector:
        matchLabels:
        app: email
    template:
        metadata:
        labels:
            app: email
        spec:
        containers:
        - name: email
            image: $INTERNAL_IP:5000/email:latest
            ports:
            - containerPort: 25
            - containerPort: 110
            - containerPort: 143
EOF
# Expose the email application to the internal metallb ip address
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: email
  namespace: default
spec:
    type: LoadBalancer
    selector:
        app: email
    ports:
    - protocol: TCP
      port: 25
      targetPort: 25
    - protocol: TCP
        port: 110
        targetPort: 110
    - protocol: TCP
        port: 143
        targetPort: 143
    loadBalancerIP: $SERVICE_IP
EOF
}

removeEmail() {
    # Remove the email application from the cluster
    kubectl delete deployment email
    kubectl delete service email
}

enableDNS() {
    # Deploy the dns application to the cluster with a yaml file
    # We are using the same container registry that was created in the createHydra.sh script
    cat <<EOF | kubectl apply -f - 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns
  namespace: default
spec:
    replicas: 3
    selector:
        matchLabels:
        app: dns
    template:
        metadata:
        labels:
            app: dns
        spec:
        containers:
        - name: dns
            image: $INTERNAL_IP:5000/dns:latest
            ports:
            - containerPort: 53
            - containerPort: 53/udp
            - containerPort: 123
            - containerPort: 123/udp
EOF
# Expose the dns application to the internal metallb ip address
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: dns
  namespace: default
spec:
    type: LoadBalancer
    selector:
        app: dns
    ports:
    - protocol: TCP
      port: 53
      targetPort: 53
    - protocol: UDP
        port: 53
        targetPort: 53
    - protocol: UDP
        port: 123
        targetPort: 123
    - protocol: TCP
        port: 123
        targetPort: 123
    loadBalancerIP: $SERVICE_IP
EOF
}

removeDNS() {
    # Remove the dns application from the cluster
    kubectl delete deployment dns
    kubectl delete service dns
}

enableWeb() {
    # Deploy the web application to the cluster with a yaml file
    # We are using the same container registry that was created in the createHydra.sh script
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: default
spec:
    replicas: 3
    selector:
        matchLabels:
        app: web
    template:
        metadata:
        labels:
            app: web
        spec:
        containers:
        - name: web
            image: $INTERNAL_IP:5000/web:latest
            ports:
            - containerPort: 80
            - containerPort: 443
EOF
# Expose the web application to the internal metallb ip address
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: default
spec:
    type: LoadBalancer
    selector:
        app: web
    ports:
    - protocol: TCP
      port: 80
      targetPort: 80
    - protocol: TCP
        port: 443
        targetPort: 443
    loadBalancerIP: $SERVICE_IP
EOF
}

removeWeb() {
    # Remove the web application from the cluster
    kubectl delete deployment web
    kubectl delete service web
}

updateEnabledServices() {
    # This will query the k3s cluster for the services that are currently enabled and update the UI
    # This will be a function that is called when the UI is first loaded and when a service is enabled or removed

    kubectl get deployments --all-namespaces | grep -q "ecommerce"
    if [ $? -eq 0 ]; then
        ECOMMERCE=true
    else
        ECOMMERCE=false
    fi

    kubectl get deployments --all-namespaces | grep -q "splunk"
    if [ $? -eq 0 ]; then
        SPLUNK=true
    else
        SPLUNK=false
    fi

    kubectl get deployments --all-namespaces | grep -q "email"
    if [ $? -eq 0 ]; then
        EMAIL=true
    else
        EMAIL=false
    fi

    kubectl get deployments --all-namespaces | grep -q "dns"
    if [ $? -eq 0 ]; then
        DNS=true
    else
        DNS=false
    fi

    kubectl get deployments --all-namespaces | grep -q "web"
    if [ $? -eq 0 ]; then
        WEB=true
    else
        WEB=false
    fi
}

drawCenteredText(){
    highlight_color=$(tput smso | sed -n l)
    highlight=${highlight_color::-1}
    # Function to draw centered text in the terminal window using tput and printf and the row number
    # This will be used to draw the UI

    # Get the terminal width
    local width=$(tput cols)

    # Calculate the position of the text
    local textwidth=${#1}
    local pos=$((($width / 2) - ($textwidth / 2)))

    # Move the cursor to the row and position
    tput cup $2 $pos

    tput sc

    # Print the text
    if [[ $3 == true ]]; then # if the text is selected then highlight it
        echo -e "$highlight$1"
    else
        echo -e "$1"
    fi

    tput rc
}

drawServices(){
    enabled="[X]"
    disabled="[ ]"
    # selected = $1

    # Draw the UI for the services
    if [[ $ECOMMERCE == true ]]; then
        [[ $1 == 0 ]] && drawCenteredText "     $enabled E-Comm     " 5 true || drawCenteredText "     $enabled E-Comm     " 5 false
    else
        [[ $1 == 0 ]] && drawCenteredText "     $disabled E-Comm     " 5 true || drawCenteredText "     $disabled E-Comm     " 5 false
    fi

    if [[ $SPLUNK == true ]]; then
        [[ $1 == 1 ]] && drawCenteredText "     $enabled Splunk     " 6 true || drawCenteredText "     $enabled Splunk     " 6 false
    else
        [[ $1 == 1 ]] && drawCenteredText "     $disabled Splunk     " 6 true || drawCenteredText "     $disabled Splunk     " 6 false
    fi

    if [[ $EMAIL == true ]]; then
        [[ $1 == 2 ]] && drawCenteredText "     $enabled Email     " 7 true || drawCenteredText "     $enabled Email     " 7 false
    else
        [[ $1 == 2 ]] && drawCenteredText "     $disabled Email     " 7 true || drawCenteredText "     $disabled Email     " 7 false
    fi

    if [[ $DNS == true ]]; then
        [[ $1 == 3 ]] && drawCenteredText "     $enabled DNS     " 8 true || drawCenteredText "     $enabled DNS     " 8 false
    else
        [[ $1 == 3 ]] && drawCenteredText "     $disabled DNS     " 8 true || drawCenteredText "     $disabled DNS     " 8 false
    fi

    if [ $WEB == true ]; then
        [[ $1 == 4 ]] && drawCenteredText "     $enabled Web     " 9 true || drawCenteredText "     $enabled Web     " 9 false
    else
        [[ $1 == 4 ]] && drawCenteredText "     $disabled Web     " 9 true || drawCenteredText "     $disabled Web     " 9 false
    fi

    [[ $1 == 5 ]] && drawCenteredText "     Exit     " 10 true || drawCenteredText "     Exit     " 10 false
}

servicesMenu(){
    selected=0
    numServices=6
    # Clear the terminal window
    clear

    # Draw the services menu
    drawCenteredText "Services" 2
    drawCenteredText "Use the arrow keys to navigate the menu" 3
    drawCenteredText "Press enter to select" 4

    while true
    do
        drawServices $selected

        # Get the user input
        read -rsn1 -d'' key
        key=$REPLY

        # Move the selection cursor
        if [[ "$key" == "A" ]]; then
            selected=$((($selected - 1 + $numServices) % $numServices))
        elif [[ "$key" == "B" ]]; then
            selected=$((($selected + 1) % $numServices))
        elif [[ "$key" == $'\x20' ]]; then
            # Turn on service
            # Beep boop Below is a test, it should be replaced with the function that enables the service and updates the service list
            if [[ $selected == 0 ]]; then
                [[ $ECOMMERCE == true ]] && ECOMMERCE=false || ECOMMERCE=true
            elif [[ $selected == 1 ]]; then
                [[ $SPLUNK == true ]] && SPLUNK=false || SPLUNK=true
            elif [[ $selected == 2 ]]; then
                [[ $EMAIL == true ]] && EMAIL=false || EMAIL=true
            elif [[ $selected == 3 ]]; then
                [[ $DNS == true ]] && DNS=false || DNS=true
            elif [[ $selected == 4 ]]; then
                [[ $WEB == true ]] && WEB=false || WEB=true
            fi
        elif [ "$key" == $'\x0a' ]; then
            break
        fi
    done

    # Return the selected service
    return $selected
}


# Create a basic UI for the user to enable and remove services navigable with arrow keys
menuSelections=("Show Nodes" "Show Pods" "Enable/Disable Services" "Exit")

drawMainMenu(){
while true
do
    selected=0
    # Clear the terminal window
    clear

    # Draw the main menu
    drawCenteredText "Hydra Control" 3
    drawCenteredText "Use the arrow keys to navigate the menu" 4
    drawCenteredText "Press enter to select" 5

    while true
    do
        for i in ${!menuSelections[@]}; do
            [[ $i == $selected ]] && drawCenteredText "${menuSelections[$i]}" $(($i + 7)) true || drawCenteredText "${menuSelections[$i]}" $(($i + 7)) false
        done

        # Get the user input
        read -s -n 1 key

        # Move the selection cursor
        if [ "$key" = "A" ]; then
            selected=$((($selected - 1 + ${#menuSelections[@]}) % ${#menuSelections[@]}))
        elif [ "$key" = "B" ]; then
            selected=$((($selected + 1) % ${#menuSelections[@]}))
        elif [ "$key" = "" ]; then
            break
        fi
    done

    clear
    # Return the selected menu item
    if [ $selected = 2 ]; then
        servicesMenu
    else
        tput cnorm
        exit 0
    fi
done
}

tput civis
drawMainMenu
tput cnorm