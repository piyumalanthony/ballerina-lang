/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package org.ballerinalang.net.ws;

import org.ballerinalang.connector.api.BallerinaConnectorException;
import org.ballerinalang.connector.api.ConnectorFuture;
import org.ballerinalang.connector.api.ConnectorFutureListener;
import org.ballerinalang.connector.api.Executor;
import org.ballerinalang.connector.api.Resource;
import org.ballerinalang.connector.impl.ConnectorUtils;
import org.ballerinalang.model.values.BStruct;
import org.ballerinalang.model.values.BValue;
import org.ballerinalang.net.http.HttpService;
import org.ballerinalang.util.exceptions.BallerinaException;
import org.wso2.carbon.messaging.CarbonMessage;
import org.wso2.carbon.transport.http.netty.contract.websocket.WebSocketBinaryMessage;
import org.wso2.carbon.transport.http.netty.contract.websocket.WebSocketCloseMessage;
import org.wso2.carbon.transport.http.netty.contract.websocket.WebSocketConnectorListener;
import org.wso2.carbon.transport.http.netty.contract.websocket.WebSocketControlMessage;
import org.wso2.carbon.transport.http.netty.contract.websocket.WebSocketInitMessage;
import org.wso2.carbon.transport.http.netty.contract.websocket.WebSocketTextMessage;
import org.wso2.carbon.transport.http.netty.message.HTTPConnectorUtil;

import java.net.ProtocolException;
import javax.websocket.Session;

/**
 * Ballerina Connector listener for WebSocket.
 *
 * @since 0.93
 */
public class BallerinaWebSocketConnectorListener implements WebSocketConnectorListener {

    @Override
    public void onMessage(WebSocketInitMessage webSocketInitMessage) {
        WebSocketService wsService = WebSocketDispatcher.findService(webSocketInitMessage);
        Resource onHandshakeResource = wsService.getResourceByName(Constants.RESOURCE_NAME_ON_HANDSHAKE);
        if (onHandshakeResource != null) {
            ConnectorFuture future = Executor.submit(onHandshakeResource, );
            future.setConnectorFutureListener(new ConnectorFutureListener() {
                @Override
                public void notifySuccess(BValue response) {
                   handleHandshake(webSocketInitMessage, wsService);
                }

                @Override
                public void notifyFailure(BallerinaConnectorException ex) {
                    throw new BallerinaException("Error: " + ex.getMessage());
                }
            });

        } else {
            handleHandshake(webSocketInitMessage, wsService);
        }
    }

    @Override
    public void onMessage(WebSocketTextMessage webSocketTextMessage) {
        CarbonMessage carbonMessage = HTTPConnectorUtil.convertWebSocketTextMessage(webSocketTextMessage);
        HttpService service = WebSocketDispatcher.findService(carbonMessage, webSocketTextMessage);
        Resource resource = WebSocketDispatcher.getResource(service, Constants.ANNOTATION_NAME_ON_TEXT_MESSAGE);
        Executor.submit(resource, carbonMessage, null);
    }

    @Override
    public void onMessage(WebSocketBinaryMessage webSocketBinaryMessage) {
        throw new BallerinaConnectorException("Binary messages are not supported!");
    }

    @Override
    public void onMessage(WebSocketControlMessage webSocketControlMessage) {
        throw new BallerinaConnectorException("Pong messages are not supported!");
    }

    @Override
    public void onMessage(WebSocketCloseMessage webSocketCloseMessage) {
        CarbonMessage carbonMessage = HTTPConnectorUtil.convertWebSocketCloseMessage(webSocketCloseMessage);
        Session serverSession = webSocketCloseMessage.getChannelSession();
        WebSocketConnectionManager.getInstance().removeSessionFromAll(serverSession);
        HttpService service = WebSocketDispatcher.findService(carbonMessage, webSocketCloseMessage);
        Resource resource = WebSocketDispatcher.getResource(service, Constants.ANNOTATION_NAME_ON_CLOSE);
        Executor.submit(resource, carbonMessage, null);
    }

    @Override
    public void onError(Throwable throwable) {
        throw new BallerinaConnectorException("Unexpected error occurred in WebSocket transport", throwable);
    }

    @Override
    public void onIdleTimeout(Session session) {
        throw new BallerinaConnectorException("Idle timeout is not supported yet");
    }


    private void handleHandshake(WebSocketInitMessage initMessage, WebSocketService wsService) {
        try {
            Session session = initMessage.handshake();
            BStruct wsConnection = wsService.createWSConnectionStruct();
            wsConnection.addNativeData(Constants.NATIVE_DATA_WEBSOCKET_SESSION, session);
            wsConnection.addNativeData(Constants.WEBSOCKET_MESSAGE, initMessage);

            WebSocketConnectionManager.getInstance().addConnection(session.getId(), wsConnection);

            Resource onOpenResource = wsService.getResourceByName(Constants.RESOURCE_NAME_ON_OPEN);
            BValue[] bValues = {wsConnection};
            if (onOpenResource == null) {
                return;
            }
            Executor.submit(onOpenResource, bValues);
        } catch (ProtocolException e) {
            throw new BallerinaException("Error occurred during handshake");
        }
    }
}
