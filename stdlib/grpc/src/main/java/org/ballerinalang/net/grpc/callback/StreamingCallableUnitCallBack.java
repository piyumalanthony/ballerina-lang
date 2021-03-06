/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
package org.ballerinalang.net.grpc.callback;

import org.ballerinalang.model.values.BError;
import org.ballerinalang.net.grpc.StreamObserver;

/**
 * Call back class registered for streaming gRPC service in B7a executor.
 *
 * @since 0.995.0
 */
public class StreamingCallableUnitCallBack extends AbstractCallableUnitCallBack {

    private StreamObserver responseSender;

    public StreamingCallableUnitCallBack(StreamObserver responseSender) {
        available.acquireUninterruptibly();
        this.responseSender = responseSender;
    }
    
    @Override
    public void notifySuccess() {
        super.notifySuccess();
    }
    
    @Override
    public void notifyFailure(BError error) {
        if (responseSender != null) {
            handleFailure(responseSender, error);
        }
        super.notifyFailure(error);
    }
}
