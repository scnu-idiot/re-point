package com.idiot.re_point.point.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class PointEarnInviteRequest {
    private Long amount;
    private String inviteId;
    private String title;
    private String detail;
}
